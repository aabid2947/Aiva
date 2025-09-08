// src/screens/App/HomeScreen.jsx
import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  ImageBackground,
  TouchableOpacity,
  Image,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
  Alert,
  Keyboard,
} from 'react-native';
import AntDesign from 'react-native-vector-icons/AntDesign';
import { auth, onAuthStateChanged } from '../../config/firebaseClient.js';
import { useAuth } from '../../context/AuthContext';
import ChatMessages from '../../components/ChatMessage';
import Sidebar from '../../components/Sidebar';
import InputTray from '../../components/InputTray';
// ConfirmationModal is now exclusively used within Sidebar, so no direct import needed here
// import ConfirmationModal from '../../components/ConfirmationModal';
import {
  initializeNotifications,
  setupForegroundListener,
  setupNotificationOpenedListener
} from '../../services/notificationService';
import {
  apiCreateNewAivaChat,
  interactWithAiva,
  apiDeleteAivaChat,
  apiListUserChats,
  apiGetChatMessages,
  apiStoreUserGoogleOAuthTokens,
} from '../../api/aivaApiService.js';
// import { configureGoogleSignIn } from '../../config/googleAuthConfig';
import { signIn as googleSignIn, configureGoogleSignIn } from '../../config/AuthService.js';
import GoogleSignInDialog from '../../components/GoogleSignInDialog.jsx';
import SuccessDialog from '../../components/SuccessDialog.jsx';
import CustomAlertDialog from '../../components/CustomAlert.jsx';

const HomeScreen = () => {
  const { signOut, user } = useAuth();
  const [messages, setMessages] = useState([]);
  const flatListRef = useRef(null);
  const [isLoadingInitial, setIsLoadingInitial] = useState(true);
  const [isSendingMessage, setIsSendingMessage] = useState(false);
  const [isAuthenticatingOAuth, setIsAuthenticatingOAuth] = useState(false);
  
  // Add ref to track if component is mounted
  const isMountedRef = useRef(true);
  const [activeChatId, setActiveChatId] = useState(null);
  const [currentChatName, setCurrentChatName] = useState("Aiva Chat");
  const [chatList, setChatList] = useState([]);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [oauthAlertPending, setOAuthAlertPending] = useState(false);
  const [showGoogleDialog, setShowGoogleDialog] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [alertVisible, setAlertVisible] = useState(false);
  const [alertMessage, setAlertMessage] = useState('');

  const [keyboardVisible, setKeyboardVisible] = useState(false);

  const HEADER_HEIGHT = 40;

  useEffect(() => {
    
    const keyboardDidShowListener = Keyboard.addListener('keyboardDidShow', () => {
      setKeyboardVisible(true);
    });
    const keyboardDidHideListener = Keyboard.addListener('keyboardDidHide', () => {
      setKeyboardVisible(false);
    });

    return () => {
      keyboardDidShowListener.remove();
      keyboardDidHideListener.remove();
    };
  }, []);

  // Ask for user permission to send notification 

useEffect(() => {
  let timeoutId;
  const unsubscribeAuth = onAuthStateChanged(async (user) => {
    if (user && isMountedRef.current) {
      // Add a small delay to ensure the app is fully loaded
      timeoutId = setTimeout(async () => {
        if (isMountedRef.current) {
          await initializeNotifications();
        }
      }, 1000);

      setupNotificationOpenedListener((remoteMessage) => {
        if (isMountedRef.current) {
          console.log('User tapped notification:', remoteMessage);
        }
      });
    } else {
      console.log("No user is logged in.");
    }
  });

  const unsubscribeForeground = setupForegroundListener();

  return () => {
    if (timeoutId) {
      clearTimeout(timeoutId);
    }
    unsubscribeAuth();
    unsubscribeForeground();
  };
}, []);

  const processAndDisplayAivaResponse = useCallback((result) => {
    if (!isMountedRef.current) return;
    
    if (result && result.aivaResponse) {
      const aiResponse = {
        id: result.id || Math.random().toString(36).substring(2, 11),
        text: result.aivaResponse,
        sender: 'ai',
        timestamp: new Date().toISOString(),
      };
      setMessages((prevMessages) => [...prevMessages, aiResponse]);

      if (result.initiateOAuth === 'google_email') {
        setOAuthAlertPending(true);
      }
    } else if (result && result.error) {
      const errorMessage = {
        id: result.id || Math.random().toString(36).substring(2, 11),
        text: `Aiva System Error: ${result.error}`,
        sender: 'ai',
        timestamp: new Date().toISOString(),
      };
      setMessages((prevMessages) => [...prevMessages, errorMessage]);
    }
  }, [setMessages]);

  const fetchUserChats = useCallback(async () => {
    try {
      const fetchedChats = await apiListUserChats();
      setChatList(fetchedChats || []);
      return fetchedChats || [];
    } catch (error) {
      console.error("Error fetching user chats:", error);
      setAlertMessage("Could not load your chat history.");
      setAlertVisible(true);
      setChatList([]);
      return [];
    }
  }, []);

  const loadMessagesForChat = useCallback(async (chatIdToLoad) => {
    if (!chatIdToLoad) return;
    setIsLoadingInitial(true);
    setMessages([]);
    try {
      const fetchedMessages = await apiGetChatMessages(chatIdToLoad);
      const formattedMessages = fetchedMessages.map(msg => ({
        id: msg.id || Math.random().toString(36).substring(2, 11),
        text: msg.content,
        sender: msg.role === 'assistant' ? 'ai' : 'user',
        timestamp: msg.timestamp,
      }));
      setMessages(formattedMessages);

      const currentChats = await fetchUserChats();
      const selectedChat = currentChats.find(c => c.id === chatIdToLoad);
      if (selectedChat) {
        setCurrentChatName(selectedChat.name || `Chat ${selectedChat.id.substring(0, 8)}`);
      }
    } catch (error) {
      console.error(`Error loading messages for chat ${chatIdToLoad}:`, error);

      setAlertMessage("Could not load messages for this chat.")
      setAlertVisible(true);
    } finally {
      setIsLoadingInitial(false);
    }
  }, [fetchUserChats, setMessages]);

  const handleCreateNewChat = useCallback(async (selectAfterCreate = true) => {
    setIsLoadingInitial(true);
    setIsSidebarOpen(false); // Close sidebar on new chat creation
    try {
      const result = await apiCreateNewAivaChat();
      if (result && result.chatId && result.initialMessage) {
        await fetchUserChats();

        if (selectAfterCreate) {
          setActiveChatId(result.chatId);
          setCurrentChatName(result.chatName || "New Chat");
          const aiStartupMessage = {
            id: result.initialMessage.id || Math.random().toString(36).substring(2, 11),
            text: result.initialMessage.text,
            sender: 'ai',
            timestamp: result.initialMessage.timestamp,
          };
          setMessages([aiStartupMessage]);
        }
      } else {
        throw new Error("Failed to create new chat or receive initial message.");
      }
    } catch (error) {
      console.error('Error creating new Aiva chat:', error);
      setAlertMessage(error.message || 'Failed to start a new chat.');
      setAlertVisible(true);
      if (selectAfterCreate) {
        setMessages([{ id: 'error-create', text: 'Failed to start new chat.', sender: 'ai', timestamp: new Date().toISOString() }]);
        setActiveChatId(null);
      }
    } finally {
      setIsLoadingInitial(false);
    }
  }, [fetchUserChats, setMessages]);

  const handleSelectChat = useCallback(async (chatId) => {
    if (chatId === activeChatId && messages.length > 0) {
      setIsSidebarOpen(false);
      return;
    }
    setActiveChatId(chatId);
    await loadMessagesForChat(chatId);
    setIsSidebarOpen(false); // Close sidebar after selecting chat
  }, [activeChatId, loadMessagesForChat, messages.length]);

  useEffect(() => {
    const initialize = async () => {
      if (!isMountedRef.current) return;
      setIsLoadingInitial(true);
      try {
        const fetchedChats = await apiListUserChats();
        if (!isMountedRef.current) return;
        setChatList(fetchedChats || []);
        if (fetchedChats && fetchedChats.length > 0) {
          const chatToLoad = activeChatId || fetchedChats[0]?.id;
          if (chatToLoad) {
            await handleSelectChat(chatToLoad);
          } else {
            await handleCreateNewChat();
          }
        } else {
          await handleCreateNewChat();
        }
      } catch (error) {
        console.error("Initialization error:", error);
        if (!isMountedRef.current) return;
        setAlertMessage("Could not initialize chat environment. A new chat will be started.");
        setAlertVisible(true);
        await handleCreateNewChat();
      } finally {
        if (isMountedRef.current) {
          setIsLoadingInitial(false);
        }
      }
    };
    initialize();
  }, []);

  const handleLogout = async () => {
    // This function is now called from Sidebar's confirmation modal
    setIsSidebarOpen(false); // Ensure sidebar closes on logout
    
    // Mark component as unmounted to prevent state updates
    isMountedRef.current = false;
    
    try {
      await signOut();
    } catch (error) {
      console.error('Logout failed:', error);
      if (isMountedRef.current) {
        setAlertMessage('Failed to log out.')
        setAlertVisible(true);
      }
    }
  };


// useEffect(()=>{
//   performGoogleOAuth();
// }, [])
  const performGoogleOAuth = useCallback(async () => {
    if (!isMountedRef.current) return;
    setIsAuthenticatingOAuth(true);
    try {
      configureGoogleSignIn()
      // this will show the native Play-Services UI, get serverAuthCode
      const result = await googleSignIn();

      if (!isMountedRef.current) return;
      // send that one-time code to your backend to exchange for tokens
      // const response = await apiStoreUserGoogleOAuthTokens({ code: serverAuthCode });
      if (result) {
        setShowSuccess(true)
      } else {
        const errText = await result.text();
        throw new Error(errText || 'Failed to connect Google account');
      }
    } catch (oauthError) {
      console.error('Google OAuth process error:', oauthError);
      if (isMountedRef.current && oauthError.code !== 'E_CANCELLED') {
        setAlertMessage(oauthError.message || 'Could not connect your Google account.');
        setAlertVisible(true);
      }
    } finally {
      if (isMountedRef.current) {
        setIsAuthenticatingOAuth(false);
      }
    }
  }, []);

  useEffect(() => {
    if (oauthAlertPending && isMountedRef.current) {
      const timer = setTimeout(() => {
        if (isMountedRef.current) {
          // simply flip this flag to render the modal
          setShowGoogleDialog(true);
        }
      }, 700);
      return () => clearTimeout(timer);
    }
  }, [oauthAlertPending, performGoogleOAuth]);

  // Hide the google sign in dialog
  const handleCancel = () => {
    setShowGoogleDialog(false);
    setOAuthAlertPending(false);
  };

  // handle confirm google signin
  const handleConfirm = () => {
    setShowGoogleDialog(false);
    performGoogleOAuth();
  };
  const handleDeleteChat = useCallback(async (chatId) => {
    // This function is now called from Sidebar's confirmation modal
    setIsLoadingInitial(true);

    const wasActive = activeChatId === chatId;

    try {
      await apiDeleteAivaChat(chatId);

      const updatedChats = await fetchUserChats();

      if (wasActive) {
        setMessages([]);
        setActiveChatId(null);
        setCurrentChatName("Select a chat");
      }

      if (updatedChats.length === 0) {
        setIsSidebarOpen(false); // Close sidebar if no chats left
        await handleCreateNewChat(); // Create a new chat automatically
      }

    } catch (error) {
      console.error('Failed to delete chat:', error);
      setAlertMessage(error.message || 'Could not delete the chat.')
      setAlertVisible(true);
      fetchUserChats(); // Refresh chat list on error as well
    } finally {
      setIsLoadingInitial(false);
    }
  }, [activeChatId, fetchUserChats, handleCreateNewChat, setMessages]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      isMountedRef.current = false;
    };
  }, []);

  // UI Rendering
  return (
    <SafeAreaView style={styles.safeArea}>
      <ImageBackground source={require('../../../assets/bg.jpg')} style={styles.container} resizeMode="cover">
        <View style={styles.overlay} />
        <View style={styles.contentWrapper}>
          <View style={styles.header}>
            <View style={styles.headerLeft}>
              <Image source={require('../../../assets/AivaNobg.png')} style={styles.aivaLogo} resizeMode="contain" />
              <View style={styles.headerAivaTextLogo}>
                <Image source={require('../../../assets/AivaText.png')} style={styles.aivaTextLogo} resizeMode="contain" />
              </View>
            </View>
            <TouchableOpacity onPress={() => {// Debugging log
              setIsSidebarOpen(true);
            }} style={styles.menuButton}>
              <AntDesign name="menu-fold" size={24} color="black" />
            </TouchableOpacity>
          </View>

          <KeyboardAvoidingView
            style={{ flex: 1 }}
            behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
            keyboardVerticalOffset={keyboardVisible ? HEADER_HEIGHT : 0}
          >
            {isLoadingInitial && messages.length === 0 ? (
              <View style={styles.chatLoadingContainer}>
                <ActivityIndicator size="large" color="#007BFF" />
                <Text style={styles.loadingText}>Loading messages...</Text>
              </View>
            ) : (
              <ChatMessages messages={messages} ref={flatListRef} />
            )}

            {activeChatId ? (
              <InputTray
                activeChatId={activeChatId}
                user={user}
                setMessages={setMessages}
                processAndDisplayAivaResponse={processAndDisplayAivaResponse}
                isAuthenticatingOAuth={isAuthenticatingOAuth}
                oauthAlertPending={oauthAlertPending}
                setIsSendingMessage={setIsSendingMessage}
                isSendingMessage={isSendingMessage}
                keyboardVisible={keyboardVisible}
              />
            ) : (
              <View style={styles.inputContainerPlaceholder}>
                <Text style={styles.noActiveChatText}>Please select or create a new chat.</Text>
              </View>
            )}
          </KeyboardAvoidingView>
        </View>
      </ImageBackground>

      <Sidebar
        isOpen={isSidebarOpen}
        onClose={() => setIsSidebarOpen(false)}
        onNewChat={handleCreateNewChat}
        onSelectChat={handleSelectChat}
        onLogoutRequested={handleLogout}
        onDeleteRequested={handleDeleteChat}
        chatList={chatList}
        activeChatId={activeChatId}
      />
      <GoogleSignInDialog
        isVisible={showGoogleDialog}
        onCancel={handleCancel}
        onConfirm={handleConfirm}
      />
      <SuccessDialog
        isVisible={showSuccess}
        title="Google Sign-In Successful!"
        message="Your Google account has been connected."
        onClose={() => setShowSuccess(false)}
      />
      <CustomAlertDialog
        isVisible={alertVisible}
        title="Error"
         message={alertMessage}
        cancelText="Dismiss"
        confirmText="Retry"
        onCancel={() => setAlertVisible(false)}
        onConfirm={() => {
          setAlertVisible(false);
          retryFetch(); // Or whatever your retry logic is
        }}
      />

    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safeArea: { flex: 1, backgroundColor: '#FFF3D9' },
  container: { flex: 1 },
  loadingContainer: { justifyContent: 'center', alignItems: 'center' },
  loadingText: { marginTop: 10, fontSize: 16, color: '#333' },
  chatLoadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  overlay: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(255, 243, 217, 0.85)', zIndex: 0 },
  contentWrapper: { flex: 1, zIndex: 1 },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 15,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
    maxHeight: 70,
    backgroundColor: 'rgba(255, 243, 217, 0.7)',
  },
  headerLeft: { flexDirection: 'row', alignItems: 'center' },
  aivaLogo: { width: 40, height: 40, marginRight: 5 },
  headerAivaTextLogo: { paddingTop: 6 },
  aivaTextLogo: { width: 80, height: 70 },
  menuButton: { padding: 5 },
  inputContainerPlaceholder: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: Platform.OS === 'ios' ? 12 : 8,
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
    backgroundColor: 'rgba(255, 243, 217, 0.95)',
    minHeight: 60,
  },
  noActiveChatText: { flex: 1, textAlign: 'center', paddingVertical: 15, fontSize: 16, color: '#777' },
});

export default HomeScreen;