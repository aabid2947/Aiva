import { API_BASE_URL } from '../config/apiConfig';
import { storeData, removeData } from '../utils/asyncStorage'; // For local storage
import { auth as firebaseAuth } from '../config/firebaseClient'; // Import the initialized auth instance


const AUTH_API_URL = `${API_BASE_URL}/auth`; // Assumes your auth endpoints are under /api/auth

export const signupUserBackend = async (email, password, displayName = null) => {
  try {
    const response = await fetch(`${AUTH_API_URL}/signup`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email, password, displayName }),
    });

    const data = await response.json();

    if (!response.ok) {
      // Backend's error handler should provide a clear message
      throw new Error(data.message || 'Signup failed');
    }
    return data;
  } catch (error) {
    console.error('API Signup Error (Backend):', error.message);
    throw error;
  }
};

// ... (your loginUserBackendVerification function remains the same)
export const loginUserBackendVerification = async (idToken) => {
    try {
        const response = await fetch(`${AUTH_API_URL}/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ idToken }),
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.message || 'Login verification failed on backend');
        }
        return data;
    } catch (error) {
        console.error('API Login Verification Error (Backend):', error.message);
        throw error;
    }
};


export const logoutUser = async () => {
  try {
    // Use the imported firebaseAuth instance
    console.log('Attempting Firebase signOut...');
    await firebaseAuth.signOut(); // Use firebaseAuth directly

    // Clear local storage regardless of backend logout
    await removeData('userToken');
    console.log('User logged out successfully from client and local storage cleared.');
    return true;
  } catch (error) {
    console.error('Client Logout Error:', error.message);
    throw error;
  }
};

// Example of a protected API call that requires the Firebase ID token
export const fetchProtectedData = async () => {
  try {
    // Use the imported firebaseAuth instance
    const user = firebaseAuth.currentUser;
    if (!user) {
      throw new Error('No authenticated user found.');
    }
    const idToken = await user.getIdToken(); // Get the current ID token

    const response = await fetch(`${API_BASE_URL}/auth/me`, { // Example protected route
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${idToken}`, // Send the ID token in the Authorization header
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || 'Failed to fetch protected data');
    }
    return data;
  } catch (error) {
    console.error('Error fetching protected data:', error.message);
    throw error;
  }
};