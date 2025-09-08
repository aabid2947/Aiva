// src/api/aivaApiService.js
import AsyncStorage from '@react-native-async-storage/async-storage';

// Attempt to read BASE_API_URL from environment variables, with a fallback for local development
// Ensure process.env.BASE_API_URL is correctly set in your build environment (e.g., through .env files and react-native-dotenv)
const API_HOST = process.env.BASE_API_URL || 'http://localhost:5000'; // Fallback to localhost:5000

const AIVA_BASE_URL = `${API_HOST}/aiva`;
const GOOGLE_TOKEN_BASE_URL = `${API_HOST}/google-tokens`;
// Define a new base URL for file uploads. You'll need to create this endpoint in your backend.
// For example, if your backend endpoint is /api/files/upload, the base would be `${API_HOST}/files`.
const FILES_BASE_URL = `${AIVA_BASE_URL}/chats`;

// Retry mechanism for API calls
async function withRetry(apiCall, maxRetries = 5, delay = 1000) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await apiCall();
    } catch (error) {
      console.log(`API attempt ${attempt}/${maxRetries} failed:`, error.message);
      
      if (attempt === maxRetries) {
        throw new Error('Sorry, server is down. Please try again later.');
      }
      
      // Wait before retrying (exponential backoff)
      await new Promise(resolve => setTimeout(resolve, delay * attempt));
    }
  }
}


async function getAuthToken() {
  const token = await AsyncStorage.getItem('userToken'); // This is your Firebase ID token
  if (!token) console.warn('aivaApiService: getAuthToken - User Firebase ID token not found.');
  return token;
}

export async function apiCreateNewAivaChat() {
  console.log('aivaApiService: apiCreateNewAivaChat - Called.');
  const token = await getAuthToken();
  if (!token) throw new Error('User not authenticated. Please log in.');

  return await withRetry(async () => {
    const response = await fetch(`${AIVA_BASE_URL}/chats`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
    });
    const responseData = await response.json();
    if (!response.ok) {
      console.error('aivaApiService: apiCreateNewAivaChat - API Error:', responseData);
      throw new Error(responseData.error || `HTTP error! status: ${response.status}`);
    }
    return responseData;
  });
}

export async function interactWithAiva(chatId, userMessageText) {
  const token = await getAuthToken();
  if (!token) throw new Error('User not authenticated. Please log in.');
  if (!chatId) throw new Error('chatId is required for interaction.');

  return await withRetry(async () => {
    const response = await fetch(`${AIVA_BASE_URL}/chats/interact`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify({ chatId: chatId, message: userMessageText }),
    });
    const responseData = await response.json();
    if (!response.ok) {
      console.error('aivaApiService: interactWithAiva - API Error:', responseData);
      throw new Error(responseData.error || `HTTP error! status: ${response.status}`);
    }
    return responseData;
  });
}

export async function apiDeleteAivaChat(chatId) {
  const token = await getAuthToken();
  if (!token) throw new Error('User not authenticated. Please log in.');
  if (!chatId) throw new Error('chatId is required for deletion.');

  return await withRetry(async () => {
    const response = await fetch(`${AIVA_BASE_URL}/chats/${chatId}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    });
    const responseData = await response.json(); // Always try to parse JSON
    if (!response.ok) {
      console.error('aivaApiService: apiDeleteAivaChat - API Error:', responseData);
      throw new Error(responseData.error || `HTTP error! status: ${response.status}`);
    }
    return responseData;
  });
}

export async function apiListUserChats() {
  console.log('aivaApiService: apiListUserChats - Called.');
  const token = await getAuthToken();

  if (!token) throw new Error('User not authenticated. Please log in.');

 
  return await withRetry(async () => {
    const response = await fetch(`${AIVA_BASE_URL}/chats`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    });
    const responseData = await response.json();
    if (!response.ok) {
      console.error('aivaApiService: apiListUserChats - API Error:', responseData);
      throw new Error(responseData.error || `HTTP error! status: ${response.status}`);
    }
    return responseData.chats || [];
  });
}

export async function apiGetChatMessages(chatId) {
  const token = await getAuthToken();
  if (!token) throw new Error('User not authenticated. Please log in.');
  if (!chatId) throw new Error('chatId is required to fetch messages.');

  return await withRetry(async () => {
    const response = await fetch(`${AIVA_BASE_URL}/chats/${chatId}/messages`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    });
    const responseData = await response.json();
    if (!response.ok) {
      console.error('aivaApiService: apiGetChatMessages - API Error:', responseData);
      throw new Error(responseData.error || `HTTP error! status: ${response.status}`);
    }
    return responseData.messages || [];
  });
}

/**
 * Sends Google OAuth tokens to the backend for storage.
 * @param {object} googleTokenData Object containing { accessToken, refreshToken?, idToken?, scope?, expiresIn? }
 * @returns {Promise<object>} The response from the backend.
 */

export async function apiStoreUserGoogleOAuthTokens(googleTokenData) {
  const appAuthToken = await getAuthToken();
  if (!appAuthToken) {
    throw new Error('User not authenticated. Please log in.');
  }

  // Now expect a `code`, not an accessToken
  if (!googleTokenData || !googleTokenData.code) {
    throw new Error('Authorization code is required.');
  }

  return await withRetry(async () => {
    const response = await fetch(`${GOOGLE_TOKEN_BASE_URL}/store`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${appAuthToken}`,
      },
      body: JSON.stringify(googleTokenData),
    });

    const responseData = await response.json();
    if (!response.ok) {
      console.error('aivaApiService: API Error:', responseData);
      throw new Error(responseData.error || `HTTP error! status: ${response.status}`);
    }

    return responseData;  // expect { sessionToken, user, message… }
  });
}

/**
 * Uploads a file to the AIVA backend.
 * @param {string} chatId The ID of the current chat session.
 * @param {object} file The file object from react-native-document-picker (e.g., { uri, name, type, size }).
 * @returns {Promise<object>} The response from the backend, including AIVA's reply.
 */
export async function apiUploadFileToAiva(chatId, file) {
  const token = await getAuthToken();
  if (!token) throw new Error('User not authenticated. Please log in.');
  if (!chatId) throw new Error('chatId is required for file upload.');
  if (!file || !file.uri || !file.name || !file.type) throw new Error('Invalid file object provided.');

  // Check file size (10MB limit for better UX)
  const maxFileSize = 50 * 1024 * 1024; // 10MB
  if (file.size && file.size > maxFileSize) {
    throw new Error(`File too large. Maximum size allowed is ${maxFileSize / (1024 * 1024)}MB. Your file is ${(file.size / (1024 * 1024)).toFixed(2)}MB.`);
  }

  console.log(`Uploading file: ${file.name}, Size: ${file.size ? (file.size / (1024 * 1024)).toFixed(2) + 'MB' : 'Unknown'}`);

  return await withRetry(async () => {
    const formData = new FormData();
    formData.append('file', {
      uri: file.uri,
      name: file.name,
      type: file.type,
    });
    formData.append('chatId', chatId); // Include chatId in the form data

    // Create a timeout promise
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => reject(new Error('Upload timeout - file might be too large or network too slow')), 300000); // 5 minutes timeout
    });

    // Create the fetch promise
    const fetchPromise = fetch(`${FILES_BASE_URL}/${chatId}/summarize`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        // 'Content-Type': 'multipart/form-data' is set automatically by React Native's fetch when FormData is used with file objects
      },
      body: formData,
    });

    // Race between fetch and timeout
    const response = await Promise.race([fetchPromise, timeoutPromise]);

    const responseData = await response.json();
    if (!response.ok) {
      console.error('aivaApiService: apiUploadFileToAiva - API Error:', responseData);
      throw new Error(responseData.error || `HTTP error! status: ${response.status}`);
    }
    return responseData;
  }, 2); // Reduce retries to 2 for large files
}
// // src/api/aivaApiService.js
// import AsyncStorage from '@react-native-async-storage/async-storage';
// import { Platform, NetInfo } from 'react-native';
// import { NativeModules } from 'react-native';

// // IMPORT YOUR NEW CUSTOM LOGGER
// const { CustomFileLogger } = NativeModules;

// // Initialize file logging at module load
// CustomFileLogger.configure({
//   maximumFileSize: 10 * 1024 * 1024, // Increased to 10 MB per file for more detailed logs
//   flushInterval: 500,                 // Reduced to 500ms for faster log writing
//   logFileName: Platform.OS === 'ios' ? 'aiva-ios-debug.log' : 'aiva-android-debug.log',
// });

// // Enhanced logging helpers with more detail
// const logInfo = (tag, message, data) => {
//   try {
//     const timestamp = new Date().toISOString();
//     const msg = data ? `${message} | DATA: ${JSON.stringify(data, null, 2)}` : message;
//     const logEntry = `[${timestamp}] [INFO] ${tag}: ${msg}`;
//     CustomFileLogger.info(logEntry);
//     console.log(logEntry);
//   } catch (e) {
//     CustomFileLogger.error(`[${new Date().toISOString()}] [ERROR] Logging failed in logInfo: ${e}`);
//   }
// };

// const logError = (tag, error, data) => {
//   try {
//     const timestamp = new Date().toISOString();
//     const msg = data ? `${error} | DATA: ${JSON.stringify(data, null, 2)}` : error;
//     const logEntry = `[${timestamp}] [ERROR] ${tag}: ${msg}`;
//     CustomFileLogger.error(logEntry);
//     console.error(logEntry);
//   } catch (e) {
//     CustomFileLogger.error(`[${new Date().toISOString()}] [ERROR] Logging failed in logError: ${e}`);
//   }
// };

// const logWarning = (tag, message, data) => {
//   try {
//     const timestamp = new Date().toISOString();
//     const msg = data ? `${message} | DATA: ${JSON.stringify(data, null, 2)}` : message;
//     const logEntry = `[${timestamp}] [WARN] ${tag}: ${msg}`;
//     CustomFileLogger.warn(logEntry);
//     console.warn(logEntry);
//   } catch (e) {
//     CustomFileLogger.error(`[${new Date().toISOString()}] [ERROR] Logging failed in logWarning: ${e}`);
//   }
// };

// // Network info logging helper
// const logNetworkInfo = async (tag) => {
//   try {
//     const netInfo = await NetInfo.fetch();
//     const networkDetails = {
//       type: netInfo.type,
//       isConnected: netInfo.isConnected,
//       isInternetReachable: netInfo.isInternetReachable,
//       details: netInfo.details
//     };
//     logInfo(tag, 'Network Information', networkDetails);
//     return networkDetails;
//   } catch (error) {
//     logError(tag, 'Failed to get network information', { error: error.message });
//     return null;
//   }
// };

// // Device info logging helper
// const logDeviceInfo = (tag) => {
//   const deviceInfo = {
//     platform: Platform.OS,
//     version: Platform.Version,
//     constants: Platform.constants
//   };
//   logInfo(tag, 'Device Information', deviceInfo);
//   return deviceInfo;
// };

// // Base URLs
// const API_HOST = process.env.BASE_API_URL || 'http://localhost:5000';
// const AIVA_BASE_URL = `${API_HOST}/aiva`;
// const GOOGLE_TOKEN_BASE_URL = `${API_HOST}/google-tokens`;
// const FILES_BASE_URL = `${AIVA_BASE_URL}/chats`;

// logInfo('aivaApiService', 'Module loaded with URLs', {
//   API_HOST,
//   AIVA_BASE_URL,
//   GOOGLE_TOKEN_BASE_URL,
//   FILES_BASE_URL
// });

// async function getAuthToken() {
//   logInfo('aivaApiService', 'getAuthToken - Starting token retrieval');
  
//   try {
//     const token = await AsyncStorage.getItem('userToken');
//     if (!token) {
//       logError('aivaApiService', 'getAuthToken - User Firebase ID token not found');
//       return null;
//     } else {
//       logInfo('aivaApiService', 'getAuthToken - Token retrieved successfully', {
//         tokenLength: token.length,
//         tokenPrefix: token.substring(0, 20) + '...'
//       });
//       return token;
//     }
//   } catch (error) {
//     logError('aivaApiService', 'getAuthToken - Error retrieving token', { error: error.message });
//     return null;
//   }
// }

// export async function apiCreateNewAivaChat() {
//   console.log(90)
//   const startTime = Date.now();
//   logInfo('aivaApiService', 'apiCreateNewAivaChat - Starting');
  
//   // Log device and network info
//   logDeviceInfo('apiCreateNewAivaChat');
//   await logNetworkInfo('apiCreateNewAivaChat');
  
//   const token = await getAuthToken();
//   if (!token) {
//     logError('apiCreateNewAivaChat', 'Authentication failed - no token');
//     throw new Error('User not authenticated. Please log in.');
//   }

//   try {
//     const requestUrl = `${AIVA_BASE_URL}/chats`;
//     const requestOptions = {
//       method: 'POST',
//       headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
//     };
    
//     logInfo('apiCreateNewAivaChat', 'Sending POST request', { 
//       url: requestUrl,
//       headers: requestOptions.headers,
//       method: requestOptions.method
//     });
    
//     const response = await fetch(requestUrl, requestOptions);
//     const responseTime = Date.now() - startTime;
    
//     logInfo('apiCreateNewAivaChat', 'Response received', { 
//       status: response.status,
//       statusText: response.statusText,
//       responseTime: `${responseTime}ms`,
//       headers: Object.fromEntries(response.headers.entries())
//     });
    
//     const responseData = await response.json();
//     logInfo('apiCreateNewAivaChat', 'Response body parsed', responseData);

//     if (!response.ok) {
//       logError('apiCreateNewAivaChat', 'API Error - Non-OK response', {
//         status: response.status,
//         statusText: response.statusText,
//         responseData,
//         responseTime: `${responseTime}ms`
//       });
//       throw new Error(responseData.error || `HTTP error! status: ${response.status}`);
//     }

//     logInfo('apiCreateNewAivaChat', 'Success', { responseData, responseTime: `${responseTime}ms` });
//     return responseData;
//   } catch (error) {
//     const responseTime = Date.now() - startTime;
//     logError('apiCreateNewAivaChat', 'Exception in apiCreateNewAivaChat', {
//       error: error.message,
//       stack: error.stack,
//       responseTime: `${responseTime}ms`
//     });
//     throw error;
//   }
// }

// export async function interactWithAiva(chatId, userMessageText) {
//   const startTime = Date.now();
//   logInfo('interactWithAiva', 'Starting interaction', { chatId, userMessageText });
  
//   // Log device and network info
//   logDeviceInfo('interactWithAiva');
//   await logNetworkInfo('interactWithAiva');
  
//   const token = await getAuthToken();
//   if (!token) {
//     logError('interactWithAiva', 'Authentication failed - no token');
//     throw new Error('User not authenticated. Please log in.');
//   }
//   if (!chatId) {
//     logError('interactWithAiva', 'Missing chatId parameter');
//     throw new Error('chatId is required for interaction.');
//   }

//   try {
//     const payload = { chatId, message: userMessageText };
//     const requestUrl = `${AIVA_BASE_URL}/chats/interact`;
//     const requestOptions = {
//       method: 'POST',
//       headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
//       body: JSON.stringify(payload),
//     };
    
//     logInfo('interactWithAiva', 'Sending POST request', { 
//       url: requestUrl,
//       payload,
//       headers: requestOptions.headers,
//       bodyLength: requestOptions.body.length
//     });
    
//     const response = await fetch(requestUrl, requestOptions);
//     const responseTime = Date.now() - startTime;
    
//     logInfo('interactWithAiva', 'Response received', { 
//       status: response.status,
//       statusText: response.statusText,
//       responseTime: `${responseTime}ms`,
//       headers: Object.fromEntries(response.headers.entries())
//     });
    
//     const responseData = await response.json();
//     logInfo('interactWithAiva', 'Response body parsed', responseData);

//     if (!response.ok) {
//       logError('interactWithAiva', 'API Error - Non-OK response', {
//         status: response.status,
//         statusText: response.statusText,
//         responseData,
//         responseTime: `${responseTime}ms`
//       });
//       throw new Error(responseData.error || `HTTP error! status: ${response.status}`);
//     }

//     logInfo('interactWithAiva', 'Success', { responseData, responseTime: `${responseTime}ms` });
//     return responseData;
//   } catch (error) {
//     const responseTime = Date.now() - startTime;
//     logError('interactWithAiva', 'Exception in interactWithAiva', {
//       error: error.message,
//       stack: error.stack,
//       responseTime: `${responseTime}ms`
//     });
//     throw error;
//   }
// }

// export async function apiDeleteAivaChat(chatId) {
//   const startTime = Date.now();
//   logInfo('apiDeleteAivaChat', 'Starting chat deletion', { chatId });
  
//   // Log device and network info
//   logDeviceInfo('apiDeleteAivaChat');
//   await logNetworkInfo('apiDeleteAivaChat');
  
//   const token = await getAuthToken();
//   if (!token) {
//     logError('apiDeleteAivaChat', 'Authentication failed - no token');
//     throw new Error('User not authenticated. Please log in.');
//   }
//   if (!chatId) {
//     logError('apiDeleteAivaChat', 'Missing chatId parameter');
//     throw new Error('chatId is required for deletion.');
//   }

//   try {
//     const requestUrl = `${AIVA_BASE_URL}/chats/${chatId}`;
//     const requestOptions = {
//       method: 'DELETE',
//       headers: { 'Authorization': `Bearer ${token}` },
//     };
    
//     logInfo('apiDeleteAivaChat', 'Sending DELETE request', { 
//       url: requestUrl,
//       headers: requestOptions.headers
//     });
    
//     const response = await fetch(requestUrl, requestOptions);
//     const responseTime = Date.now() - startTime;
    
//     logInfo('apiDeleteAivaChat', 'Response received', { 
//       status: response.status,
//       statusText: response.statusText,
//       responseTime: `${responseTime}ms`,
//       headers: Object.fromEntries(response.headers.entries())
//     });
    
//     const responseData = await response.json();
//     logInfo('apiDeleteAivaChat', 'Response body parsed', responseData);

//     if (!response.ok) {
//       logError('apiDeleteAivaChat', 'API Error - Non-OK response', {
//         status: response.status,
//         statusText: response.statusText,
//         responseData,
//         responseTime: `${responseTime}ms`
//       });
//       throw new Error(responseData.error || `HTTP error! status: ${response.status}`);
//     }

//     logInfo('apiDeleteAivaChat', 'Success', { responseData, responseTime: `${responseTime}ms` });
//     return responseData;
//   } catch (error) {
//     const responseTime = Date.now() - startTime;
//     logError('apiDeleteAivaChat', 'Exception in apiDeleteAivaChat', {
//       error: error.message,
//       stack: error.stack,
//       responseTime: `${responseTime}ms`
//     });
//     throw error;
//   }
// }

// export async function apiListUserChats() {
//   const startTime = Date.now();
//   logInfo('apiListUserChats', 'Starting chat list retrieval');
  
//   // Log device and network info
//   logDeviceInfo('apiListUserChats');
//   await logNetworkInfo('apiListUserChats');
  
//   const token = await getAuthToken();
//   if (!token) {
//     logError('apiListUserChats', 'Authentication failed - no token');
//     throw new Error('User not authenticated. Please log in.');
//   }

//   try {
//     const requestUrl = `${AIVA_BASE_URL}/chats`;
//     const requestOptions = {
//       method: 'GET',
//       headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
//     };
    
//     logInfo('apiListUserChats', 'Sending GET request', { 
//       url: requestUrl,
//       headers: requestOptions.headers
//     });
    
//     const response = await fetch(requestUrl, requestOptions);
//     const responseTime = Date.now() - startTime;
    
//     logInfo('apiListUserChats', 'Response received', { 
//       status: response.status,
//       statusText: response.statusText,
//       responseTime: `${responseTime}ms`,
//       headers: Object.fromEntries(response.headers.entries())
//     });
    
//     const responseData = await response.json();
//     logInfo('apiListUserChats', 'Response body parsed', {
//       ...responseData,
//       chatsCount: responseData.chats ? responseData.chats.length : 0
//     });

//     if (!response.ok) {
//       logError('apiListUserChats', 'API Error - Non-OK response', {
//         status: response.status,
//         statusText: response.statusText,
//         responseData,
//         responseTime: `${responseTime}ms`
//       });
//       throw new Error(responseData.error || `HTTP error! status: ${response.status}`);
//     }

//     logInfo('apiListUserChats', 'Success', { 
//       chatsCount: responseData.chats ? responseData.chats.length : 0,
//       responseTime: `${responseTime}ms`
//     });
//     return responseData.chats || [];
//   } catch (error) {
//     const responseTime = Date.now() - startTime;
//     logError('apiListUserChats', 'Exception in apiListUserChats', {
//       error: error.message,
//       stack: error.stack,
//       responseTime: `${responseTime}ms`
//     });
//     throw error;
//   }
// }

// export async function apiGetChatMessages(chatId) {
//   const startTime = Date.now();
//   logInfo('apiGetChatMessages', 'Starting message retrieval', { chatId });
  
//   // Log device and network info
//   logDeviceInfo('apiGetChatMessages');
//   await logNetworkInfo('apiGetChatMessages');
  
//   const token = await getAuthToken();
//   if (!token) {
//     logError('apiGetChatMessages', 'Authentication failed - no token');
//     throw new Error('User not authenticated. Please log in.');
//   }
//   if (!chatId) {
//     logError('apiGetChatMessages', 'Missing chatId parameter');
//     throw new Error('chatId is required to fetch messages.');
//   }

//   try {
//     const requestUrl = `${AIVA_BASE_URL}/chats/${chatId}/messages`;
//     const requestOptions = {
//       method: 'GET',
//       headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
//     };
    
//     logInfo('apiGetChatMessages', 'Sending GET request', { 
//       url: requestUrl,
//       headers: requestOptions.headers
//     });
    
//     const response = await fetch(requestUrl, requestOptions);
//     const responseTime = Date.now() - startTime;
    
//     logInfo('apiGetChatMessages', 'Response received', { 
//       status: response.status,
//       statusText: response.statusText,
//       responseTime: `${responseTime}ms`,
//       headers: Object.fromEntries(response.headers.entries())
//     });
    
//     const responseData = await response.json();
//     logInfo('apiGetChatMessages', 'Response body parsed', {
//       ...responseData,
//       messagesCount: responseData.messages ? responseData.messages.length : 0
//     });

//     if (!response.ok) {
//       logError('apiGetChatMessages', 'API Error - Non-OK response', {
//         status: response.status,
//         statusText: response.statusText,
//         responseData,
//         responseTime: `${responseTime}ms`
//       });
//       throw new Error(responseData.error || `HTTP error! status: ${response.status}`);
//     }

//     logInfo('apiGetChatMessages', 'Success', { 
//       messagesCount: responseData.messages ? responseData.messages.length : 0,
//       responseTime: `${responseTime}ms`
//     });
//     return responseData.messages || [];
//   } catch (error) {
//     const responseTime = Date.now() - startTime;
//     logError('apiGetChatMessages', 'Exception in apiGetChatMessages', {
//       error: error.message,
//       stack: error.stack,
//       responseTime: `${responseTime}ms`
//     });
//     throw error;
//   }
// }

// export async function apiStoreUserGoogleOAuthTokens(googleTokenData) {
//   const startTime = Date.now();
//   logInfo('apiStoreUserGoogleOAuthTokens', 'Starting OAuth token storage', {
//     hasCode: !!googleTokenData?.code,
//     codeLength: googleTokenData?.code?.length
//   });
  
//   // Log device and network info
//   logDeviceInfo('apiStoreUserGoogleOAuthTokens');
//   await logNetworkInfo('apiStoreUserGoogleOAuthTokens');
  
//   const appAuthToken = await getAuthToken();
//   if (!appAuthToken) {
//     logError('apiStoreUserGoogleOAuthTokens', 'Authentication failed - no token');
//     throw new Error('User not authenticated. Please log in.');
//   }
//   if (!googleTokenData || !googleTokenData.code) {
//     logError('apiStoreUserGoogleOAuthTokens', 'Missing authorization code', { googleTokenData });
//     throw new Error('Authorization code is required.');
//   }

//   try {
//     const requestUrl = `${GOOGLE_TOKEN_BASE_URL}/store`;
//     const requestOptions = {
//       method: 'POST',
//       headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${appAuthToken}` },
//       body: JSON.stringify(googleTokenData),
//     };
    
//     logInfo('apiStoreUserGoogleOAuthTokens', 'Sending POST request', { 
//       url: requestUrl,
//       payload: googleTokenData,
//       headers: requestOptions.headers,
//       bodyLength: requestOptions.body.length
//     });
    
//     const response = await fetch(requestUrl, requestOptions);
//     const responseTime = Date.now() - startTime;
    
//     logInfo('apiStoreUserGoogleOAuthTokens', 'Response received', { 
//       status: response.status,
//       statusText: response.statusText,
//       responseTime: `${responseTime}ms`,
//       headers: Object.fromEntries(response.headers.entries())
//     });
    
//     const responseData = await response.json();
//     logInfo('apiStoreUserGoogleOAuthTokens', 'Response body parsed', responseData);

//     if (!response.ok) {
//       logError('apiStoreUserGoogleOAuthTokens', 'API Error - Non-OK response', {
//         status: response.status,
//         statusText: response.statusText,
//         responseData,
//         responseTime: `${responseTime}ms`
//       });
//       throw new Error(responseData.error || `HTTP error! status: ${response.status}`);
//     }

//     logInfo('apiStoreUserGoogleOAuthTokens', 'Success', { responseData, responseTime: `${responseTime}ms` });
//     return responseData;
//   } catch (error) {
//     const responseTime = Date.now() - startTime;
//     logError('apiStoreUserGoogleOAuthTokens', 'Exception in apiStoreUserGoogleOAuthTokens', {
//       error: error.message,
//       stack: error.stack,
//       responseTime: `${responseTime}ms`
//     });
//     throw error;
//   }
// }

// export async function apiUploadFileToAiva(chatId, file) {
//   const startTime = Date.now();
//   logInfo('apiUploadFileToAiva', '🚀 STARTING FILE UPLOAD - This is the critical function', { 
//     chatId, 
//     fileName: file?.name,
//     fileSize: file?.size,
//     fileType: file?.type,
//     fileUri: file?.uri
//   });
  
//   // Enhanced device and network logging for file upload
//   const deviceInfo = logDeviceInfo('apiUploadFileToAiva');
//   const networkInfo = await logNetworkInfo('apiUploadFileToAiva');
  
//   // Log additional network-specific details that might affect file uploads
//   logInfo('apiUploadFileToAiva', '📱 NETWORK ANALYSIS FOR FILE UPLOAD', {
//     networkType: networkInfo?.type,
//     connectionSpeed: networkInfo?.details?.cellularGeneration,
//     isWifi: networkInfo?.type === 'wifi',
//     is4G: networkInfo?.details?.cellularGeneration === '4g',
//     is5G: networkInfo?.details?.cellularGeneration === '5g',
//     signalStrength: networkInfo?.details?.strength
//   });
  
//   const token = await getAuthToken();
//   if (!token) {
//     logError('apiUploadFileToAiva', '❌ Authentication failed - no token');
//     throw new Error('User not authenticated. Please log in.');
//   }
//   if (!chatId) {
//     logError('apiUploadFileToAiva', '❌ Missing chatId parameter');
//     throw new Error('chatId is required for file upload.');
//   }
//   if (!file || !file.uri || !file.name || !file.type) {
//     logError('apiUploadFileToAiva', '❌ Invalid file object provided', {
//       hasFile: !!file,
//       hasUri: !!file?.uri,
//       hasName: !!file?.name,
//       hasType: !!file?.type,
//       fileObject: file
//     });
//     throw new Error('Invalid file object provided.');
//   }

//   try {
//     // Log detailed file information
//     logInfo('apiUploadFileToAiva', '📄 DETAILED FILE INFORMATION', {
//       fileName: file.name,
//       fileType: file.type,
//       fileSize: file.size,
//       fileUri: file.uri,
//       fileSizeInMB: file.size ? (file.size / (1024 * 1024)).toFixed(2) + ' MB' : 'Unknown'
//     });

//     // Create FormData with detailed logging
//     logInfo('apiUploadFileToAiva', '📦 CREATING FORM DATA');
//     const formData = new FormData();
    
//     // Log before appending file
//     logInfo('apiUploadFileToAiva', '📎 APPENDING FILE TO FORM DATA', {
//       uri: file.uri,
//       name: file.name,
//       type: file.type
//     });
//     formData.append('file', { uri: file.uri, name: file.name, type: file.type });
    
//     // Log before appending chatId
//     logInfo('apiUploadFileToAiva', '💬 APPENDING CHAT ID TO FORM DATA', { chatId });
//     formData.append('chatId', chatId);
    
//     logInfo('apiUploadFileToAiva', '✅ FORM DATA CREATED SUCCESSFULLY');

//     // Prepare request details
//     const requestUrl = `${FILES_BASE_URL}/${chatId}/summarize`;
//     const requestOptions = {
//       method: 'POST',
//       headers: { 'Authorization': `Bearer ${token}` },
//       body: formData,
//     };
    
//     logInfo('apiUploadFileToAiva', '🌐 PREPARING MULTIPART REQUEST', { 
//       url: requestUrl,
//       method: requestOptions.method,
//       hasAuthHeader: !!requestOptions.headers.Authorization,
//       authHeaderLength: requestOptions.headers.Authorization.length,
//       contentType: 'multipart/form-data (automatically set by FormData)'
//     });
    
//     // Log the exact moment before sending request
//     logInfo('apiUploadFileToAiva', '⏰ SENDING REQUEST NOW - TIMESTAMP: ' + new Date().toISOString());
    
//     const response = await fetch(requestUrl, requestOptions);
//     const responseTime = Date.now() - startTime;
    
//     // Immediate response logging
//     logInfo('apiUploadFileToAiva', '📥 RESPONSE RECEIVED', { 
//       status: response.status,
//       statusText: response.statusText,
//       responseTime: `${responseTime}ms`,
//       ok: response.ok,
//       type: response.type,
//       url: response.url,
//       redirected: response.redirected,
//       headers: Object.fromEntries(response.headers.entries())
//     });
    
//     // Log response headers in detail
//     const responseHeaders = Object.fromEntries(response.headers.entries());
//     logInfo('apiUploadFileToAiva', '📋 RESPONSE HEADERS ANALYSIS', {
//       contentType: responseHeaders['content-type'],
//       contentLength: responseHeaders['content-length'],
//       server: responseHeaders['server'],
//       allHeaders: responseHeaders
//     });
    
//     // Attempt to read response - this is where JSON parse errors often occur
//     logInfo('apiUploadFileToAiva', '🔍 ATTEMPTING TO PARSE RESPONSE BODY');
    
//     let responseData;
//     try {
//       responseData = await response.json();
//       logInfo('apiUploadFileToAiva', '✅ RESPONSE BODY PARSED SUCCESSFULLY', responseData);
//     } catch (parseError) {
//       logError('apiUploadFileToAiva', '❌ JSON PARSE ERROR - THIS IS THE ISSUE!', {
//         parseError: parseError.message,
//         parseErrorStack: parseError.stack,
//         responseStatus: response.status,
//         responseStatusText: response.statusText,
//         responseHeaders: responseHeaders,
//         responseTime: `${responseTime}ms`
//       });
      
//       // Try to read response as text to see what we actually received
//       try {
//         const responseText = await response.text();
//         logError('apiUploadFileToAiva', '📄 RESPONSE AS TEXT (NOT JSON)', {
//           responseText: responseText,
//           textLength: responseText.length,
//           firstChars: responseText.substring(0, 500)
//         });
//       } catch (textError) {
//         logError('apiUploadFileToAiva', '❌ FAILED TO READ RESPONSE AS TEXT TOO', {
//           textError: textError.message
//         });
//       }
      
//       throw new Error(`JSON Parse Error: ${parseError.message} - Response status: ${response.status}`);
//     }

//     if (!response.ok) {
//       logError('apiUploadFileToAiva', '❌ API ERROR - NON-OK RESPONSE', {
//         status: response.status,
//         statusText: response.statusText,
//         responseData,
//         responseTime: `${responseTime}ms`,
//         networkType: networkInfo?.type,
//         cellularGeneration: networkInfo?.details?.cellularGeneration
//       });
//       throw new Error(responseData.error || `HTTP error! status: ${response.status}`);
//     }

//     logInfo('apiUploadFileToAiva', '🎉 FILE UPLOAD SUCCESS!', { 
//       responseData, 
//       responseTime: `${responseTime}ms`,
//       networkType: networkInfo?.type,
//       cellularGeneration: networkInfo?.details?.cellularGeneration,
//       fileSize: file.size
//     });
//     return responseData;
//   } catch (error) {
//     const responseTime = Date.now() - startTime;
//     logError('apiUploadFileToAiva', '💥 EXCEPTION IN FILE UPLOAD - CRITICAL ERROR', {
//       error: error.message,
//       errorName: error.name,
//       errorStack: error.stack,
//       responseTime: `${responseTime}ms`,
//       chatId,
//       fileName: file?.name,
//       fileSize: file?.size,
//       networkType: networkInfo?.type,
//       cellularGeneration: networkInfo?.details?.cellularGeneration,
//       devicePlatform: deviceInfo?.platform,
//       deviceVersion: deviceInfo?.version
//     });
    
//     // Additional error analysis
//     if (error.message.includes('JSON')) {
//       logError('apiUploadFileToAiva', '🔍 JSON PARSE ERROR ANALYSIS', {
//         errorType: 'JSON_PARSE_ERROR',
//         likelyCause: 'Server returned non-JSON response, possibly HTML error page or malformed response',
//         debugSuggestion: 'Check server logs and response content-type header'
//       });
//     }
    
//     if (error.message.includes('Network')) {
//       logError('apiUploadFileToAiva', '🔍 NETWORK ERROR ANALYSIS', {
//         errorType: 'NETWORK_ERROR',
//         networkType: networkInfo?.type,
//         cellularGeneration: networkInfo?.details?.cellularGeneration,
//         suggestion: '5G vs 4G network handling difference detected'
//       });
//     }
    
//     throw error;
//   }
// }