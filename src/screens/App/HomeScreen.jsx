// src/screens/App/HomeScreen.js
import React from 'react';
import { View, Text, StyleSheet, SafeAreaView, ImageBackground, TextInput, TouchableOpacity, Image, Alert } from 'react-native';
import Feather from 'react-native-vector-icons/Feather';
import AntDesign from 'react-native-vector-icons/AntDesign';
import { logoutUser } from '../../api/auth'; // Import logout function

const HomeScreen = () => {

  const handleLogout = async () => {
    try {
      await logoutUser();
      // App.js's onAuthStateChanged listener will handle navigation to AuthNavigator
      // Alert.alert('Logged Out', 'You have been successfully logged out.');
    } catch (error) {
      console.error('Logout failed:', error);
      Alert.alert('Logout Error', 'Failed to log out. Please try again.');
    }
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <ImageBackground
        source={require('../../../assets/bg.jpg')}
        style={styles.container}
        resizeMode="cover"
      >
        {/* Overlay to dim the background */}
        <View style={styles.overlay} />

        {/* All content sits above the overlay */}
        <View style={styles.contentWrapper}>
          {/* Header */}
          <View style={styles.header}>
            <View style={styles.headerLeft}>
              <Image source={require('../../../assets/AivaNobg.png')} style={styles.aivaLogo} resizeMode="contain" />
             
            <View>
               <Image source={require('../../../assets/AivaText.png')} style={styles.aivaTextLogo} resizeMode="contain" />
              
            </View>
            </View>
            <View style={styles.headerRight}>
              {/* <TouchableOpacity style={styles.sidebarIcon}>
                <Feather name="menu" size={24} color="black" />
              </TouchableOpacity> */}
              <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
                <AntDesign name="logout" size={24} color="black" />
              </TouchableOpacity>
            </View>
          </View>

          {/* Messages */}
          <View style={styles.messagesContainer}>
            <Text style={styles.placeholderText}>Chat messages will appear here.</Text>
            <Text style={styles.placeholderSubText}>Start a conversation by typing below.</Text>
          </View>

          {/* Input */}
          <View style={styles.inputContainer}>
            <TextInput
              style={styles.textInput}
              placeholder="Message..."
              placeholderTextColor="#888"
              multiline
              maxHeight={100}
            />
            <TouchableOpacity style={styles.sendButton}>
              <AntDesign name="arrowup" size={24} color="black" />
            </TouchableOpacity>
          </View>
        </View>
      </ImageBackground>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    // backgroundColor: '#fff3d9',
  },
  container: {
    flex: 1,
    // backgroundColor: '#fff3d9',
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(255, 243, 217, 0.85)', // Creamy transparent overlay
    zIndex: 0,
  },

  contentWrapper: {
    flex: 1,
    zIndex: 1, // Above the overlay
    
  },

  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 15,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',

    // backgroundColor: '#fff3d9',
  },
  aivaLogo: {
    width: 50,
    height: 50,
    // borderWidth:1,
    objectFit: 'cover',
    tintColor: '#007BFF',


    // marginBottom: 30,
  },
  aivaTextLogo: {
    width: 100,
    height:60,
    objectFit: 'cover',
    // borderWidth:1
    // marginBottom: 30,
  },
  headerLeft: {
    // borderWidth:1,
    flex:1,
    flexDirection:'row',
    alignContent:'center'
  },
  appLogoText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
  },
  headerRight: {
    flexDirection: 'row', // To align menu and logout horizontally
    alignItems: 'center',
  },
  sidebarIcon: {
    padding: 5,
    marginRight: 10, // Space between menu and logout
  },
  logoutButton: {
    padding: 5,
  },
  messagesContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
    // backgroundColor: '#fff3d9',
  },
  placeholderText: {
    fontSize: 18,
    color: '#666',
    marginBottom: 10,
  },
  placeholderSubText: {
    fontSize: 14,
    color: '#999',
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 15,
    paddingVertical: 10,
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
    backgroundColor: '#fff3d9',
  },
  textInput: {
    flex: 1,
    minHeight: 50,
    maxHeight: 100,
    borderColor: '#ccc',
    borderWidth: 1,
    borderRadius: 24,
    paddingHorizontal: 15,
    paddingVertical: 8,
    marginRight: 10,
    fontSize: 16,
    // backgroundColor: '#fff3d9',
  },
  sendButton: {
    // backgroundColor: '#007bff',
    borderWidth:1,
    borderColor: '#ccc',
    borderRadius: 20,
    width: 40,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default HomeScreen;