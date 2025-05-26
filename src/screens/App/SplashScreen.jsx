import React, { useEffect } from 'react';
import { View, Text, Image, StyleSheet } from 'react-native';

const SplashScreen = ({ navigation }) => {
//
  return (
    <View style={styles.container}>
      {/* <View style={styles.topSection}>
        <Image source={require('../../../assets/Aiva.jpg')} style={styles.aivaLogo}  />
      </View> */}
      <View style={styles.centerSection}>
         <Image source={require('../../../assets/AivaText.png')} style={styles.aivaTextLogo}  />
        <Image source={require('../../../assets/Aiva.jpg')} style={styles.aivaLogo} resizeMode="contain" />
        <Text style={styles.title}>Artificial Intelligence{"\n"}Virtual Assistance</Text>
      </View>
      <View style={styles.bottomSection}>
        <Image source={require('../../../assets/thumb.png')} style={styles.fingerprint} resizeMode="contain" />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff3d9',
    alignItems: 'center',
    justifyContent:'center',
    // justifyContent: 'space-between',
    paddingVertical: 40,
  },
  topSection: {
    // borderWidth:1,
    width: '100%',
    alignItems: 'center',
    justifyContent:'center',
    marginTop: 40,
  },
  aivaTextLogo: {
    
    marginLeft:10,
    objectFit: 'cover',
    width: 170,
    height: 100,
    // borderWidth:1,
    marginBottom: 20,
  },
  centerSection: {
    alignItems: 'center',
    justifyContent: 'center',
    flex: 1,
    // borderWidth:1,
  },
  aivaLogo: {
    width: 160,
    height: 160,
    marginBottom: 30,
  },
  title: {
    fontSize: 20,
    color: '#222',
    textAlign: 'center',
    fontWeight: '500',
    marginTop: 10,
  },
  bottomSection: {
    alignItems: 'center',
    marginBottom: 10,
  },
  fingerprint: {
    width: 40,
    height: 40,
    opacity: 0.3,
  },
});

export default SplashScreen; 