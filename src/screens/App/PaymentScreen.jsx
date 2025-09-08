// import React, { useState } from 'react';
// import {
//   StyleSheet,
//   Text,
//   View,
//   TextInput,
//   TouchableOpacity,
//   ActivityIndicator,
//   Alert,
//   Keyboard,
//   ScrollView,
// } from 'react-native';
// import axios from 'axios';

// // Replace with your backend server URL.
// // For development, you might use your computer's IP address or ngrok.
// const API_BASE_URL = 'https://aiva-backend.duckdns.org'; // Example: Replace with your actual IP

// const PaymentScreen = () => {
//   const [phoneNumber, setPhoneNumber] = useState('');
//   const [amount, setAmount] = useState('');
//   const [loading, setLoading] = useState(false);

//   const handlePayment = async () => {
//     Keyboard.dismiss();

//     if (!phoneNumber || !amount) {
//       Alert.alert('Error', 'Please enter both phone number and amount.');
//       return;
//     }

//     // Basic validation for phone number (should be in 254xxxxxxxxx format)
//     if (!/^254\d{9}$/.test(phoneNumber)) {
//         Alert.alert('Error', 'Phone number must be in the format 254XXXXXXXXX.');
//         return;
//     }
    
//     setLoading(true);

//     try {
//       const payload = {
//         phoneNumber,
//         amount: parseInt(amount, 10),
//         accountRef: `AIVA_${Date.now()}`, // Example account reference
//         transactionDesc: 'Payment for Aiva Pro',
//       };

//       const response = await axios.post(`${API_BASE_URL}/api/payments/stk-push`, payload);

//       console.log('Backend Response:', response.data);

//       const responseCode = response.data.ResponseCode;
//       if (responseCode === '0') {
//         Alert.alert(
//           'Request Sent',
//           'Please check your phone and enter your M-Pesa PIN to complete the payment.'
//         );
//       } else {
//          Alert.alert('Request Failed', response.data.ResponseDescription || 'An unknown error occurred.');
//       }

//     } catch (error) {
//       console.error('Payment Error:', error.response ? error.response.data : error.message);
//       Alert.alert('Error', 'An error occurred while trying to initiate the payment. Please try again.');
//     } finally {
//       setLoading(false);
//     }
//   };

//   return (
//     <ScrollView contentContainerStyle={styles.container}>
//       <View style={styles.formContainer}>
//         <Text style={styles.title}>M-Pesa Payment</Text>
//         <Text style={styles.subtitle}>Enter payment details to continue</Text>

//         <TextInput
//           style={styles.input}
//           placeholder="Phone Number (e.g., 254712345678)"
//           placeholderTextColor="#888"
//           keyboardType="phone-pad"
//           value={phoneNumber}
//           onChangeText={setPhoneNumber}
//         />

//         <TextInput
//           style={styles.input}
//           placeholder="Amount (KES)"
//           placeholderTextColor="#888"
//           keyboardType="number-pad"
//           value={amount}
//           onChangeText={setAmount}
//         />

//         <TouchableOpacity
//           style={[styles.button, loading && styles.buttonDisabled]}
//           onPress={handlePayment}
//           disabled={loading}
//         >
//           {loading ? (
//             <ActivityIndicator size="small" color="#fff" />
//           ) : (
//             <Text style={styles.buttonText}>Pay KES {amount || '0'}</Text>
//           )}
//         </TouchableOpacity>
//       </View>
//     </ScrollView>
//   );
// };

// const styles = StyleSheet.create({
//   container: {
//     flexGrow: 1,
//     justifyContent: 'center',
//     alignItems: 'center',
//     backgroundColor: '#f0f4f7',
//     padding: 20,
//   },
//   formContainer: {
//     width: '100%',
//     maxWidth: 400,
//     backgroundColor: '#fff',
//     padding: 25,
//     borderRadius: 15,
//     shadowColor: '#000',
//     shadowOffset: { width: 0, height: 5 },
//     shadowOpacity: 0.1,
//     shadowRadius: 10,
//     elevation: 5,
//   },
//   title: {
//     fontSize: 26,
//     fontWeight: 'bold',
//     color: '#333',
//     textAlign: 'center',
//     marginBottom: 10,
//   },
//   subtitle: {
//     fontSize: 16,
//     color: '#666',
//     textAlign: 'center',
//     marginBottom: 30,
//   },
//   input: {
//     width: '100%',
//     height: 50,
//     backgroundColor: '#f8f8f8',
//     borderWidth: 1,
//     borderColor: '#ddd',
//     borderRadius: 8,
//     paddingHorizontal: 15,
//     marginBottom: 20,
//     fontSize: 16,
//     color: '#333',
//   },
//   button: {
//     width: '100%',
//     height: 50,
//     backgroundColor: '#4CAF50',
//     justifyContent: 'center',
//     alignItems: 'center',
//     borderRadius: 8,
//     marginTop: 10,
//   },
//   buttonDisabled: {
//     backgroundColor: '#A5D6A7',
//   },
//   buttonText: {
//     color: '#fff',
//     fontSize: 18,
//     fontWeight: 'bold',
//   },
// });

// export default PaymentScreen;
