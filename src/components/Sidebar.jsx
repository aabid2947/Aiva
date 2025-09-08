// src/components/Sidebar.jsx
import React, { useEffect, useRef, useState, useCallback } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  FlatList,
  Dimensions,
  ImageBackground,
  Modal,
  Animated,
  Platform,
  Alert,
} from 'react-native';
import AntDesign from 'react-native-vector-icons/AntDesign';
import ConfirmationModal from './ConfirmationModal';

const { width } = Dimensions.get('window');
const SIDEBAR_WIDTH = width * 0.75;

const Sidebar = ({
  isOpen,
  onClose,
  onNewChat,
  onSelectChat,
  onLogoutRequested,
  onDeleteRequested,
  chatList = [],
  activeChatId,
}) => {
  const slideAnim = useRef(new Animated.Value(SIDEBAR_WIDTH)).current;
  const [isLogoutConfirmModalVisible, setIsLogoutConfirmModalVisible] = useState(false);
  const [isDeleteConfirmModalVisible, setIsDeleteConfirmModalVisible] = useState(false);
  const [chatToDelete, setChatToDelete] = useState(null);

  useEffect(() => {
    // Add listener to log animation value
    slideAnim.addListener(({ value }) => {
      // console.log('slideAnim value:', value); // Uncomment for more detailed debugging
    });

    if (isOpen) {
      Animated.timing(slideAnim, {
        toValue: 0,
        duration: 300,
        useNativeDriver: true,
      }).start();
      console.log('Sidebar opened!');
    } else {
      Animated.timing(slideAnim, {
        toValue: SIDEBAR_WIDTH,
        duration: 300,
        useNativeDriver: true,
      }).start();
    }

    // Cleanup listener on unmount
    return () => {
      slideAnim.removeAllListeners();
    };
  }, [isOpen, slideAnim]);

  const handleLogoutPress = useCallback(() => {
    setIsLogoutConfirmModalVisible(true);
  }, []);

  const handleConfirmLogout = useCallback(() => {
    setIsLogoutConfirmModalVisible(false);
    onLogoutRequested();
  }, [onLogoutRequested]);

  const handleDeletePress = useCallback((chatId) => {
    const chat = chatList.find(c => c.id === chatId);
    if (chat) {
      setChatToDelete(chat);
      setIsDeleteConfirmModalVisible(true);
    }
  }, [chatList]);

  const handleConfirmDelete = useCallback(() => {
    if (chatToDelete) {
      setIsDeleteConfirmModalVisible(false);
      onDeleteRequested(chatToDelete.id);
      setChatToDelete(null);
    }
  }, [chatToDelete, onDeleteRequested]);

  const handleCancelDelete = useCallback(() => {
    setIsDeleteConfirmModalVisible(false);
    setChatToDelete(null);
  }, []);

  const renderChatItem = useCallback(({ item }) => (
    <View style={styles.chatItemContainer}>
      <TouchableOpacity
        style={[
          styles.chatItem,
          item.id === activeChatId && styles.activeChatItem,
        ]}
        onPress={() => {
          onSelectChat(item.id);
          onClose(); // Close sidebar after selecting a chat
        }}>
        <Text
          style={[
            styles.chatItemText,
            item.id === activeChatId && styles.activeChatItemText,
          ]}
          numberOfLines={1}>
          {item.name || `Chat ${item.id.substring(0, 8)}`}
        </Text>
      </TouchableOpacity>
      <TouchableOpacity onPress={() => handleDeletePress(item.id)} style={styles.deleteIcon}>
        <AntDesign name="delete" size={20} color="#c0392b" />
      </TouchableOpacity>
    </View>
  ), [activeChatId, onSelectChat, handleDeletePress, onClose]);

  return (
    <Modal
      animationType="fade"
      transparent={true}
      visible={isOpen}
      onRequestClose={onClose}
    >
      <TouchableOpacity
        style={styles.modalOverlay}
        activeOpacity={1}
        onPressOut={onClose}
      >
        <Animated.View
          style={[styles.sidebarContainer, { transform: [{ translateX: slideAnim }] }]}
          onStartShouldSetResponder={() => true} // Prevent closing when interacting with sidebar content
        >
          <SafeAreaView style={{flex: 1}}> 
            <ImageBackground
              source={require('../../assets/bg.jpg')}
              style={styles.container}
              resizeMode="cover"
            >
              <View style={styles.overlay} />
              <View style={styles.sidebarHeader}>
                <TouchableOpacity onPress={onClose} style={styles.closeButton}>
                  <AntDesign name="close" size={24} color="#333" />
                </TouchableOpacity>
                <Text style={styles.sidebarTitle}>Aiva Chats</Text>
              </View>

              <TouchableOpacity style={styles.newChatButton} onPress={() => { onNewChat(); onClose(); }}>
                <AntDesign name="pluscircleo" size={20} color="#fff" style={styles.newChatIcon} />
                <Text style={styles.newChatButtonText}>New Chat</Text>
              </TouchableOpacity>

              <FlatList
                data={chatList}
                renderItem={renderChatItem}
                keyExtractor={(item) => item.id}
                style={styles.chatList}
                ListEmptyComponent={<Text style={styles.emptyListText}>No chats yet.</Text>}
              />

              <TouchableOpacity style={styles.logoutButton} onPress={handleLogoutPress}>
                <AntDesign name="logout" size={20} color="#333" style={styles.logoutIcon} />
                <Text style={styles.logoutButtonText}>Logout</Text>
              </TouchableOpacity>
            </ImageBackground>
          </SafeAreaView>
        </Animated.View>
      </TouchableOpacity>

      {/* Logout Confirmation Modal */}
      <ConfirmationModal
        isVisible={isLogoutConfirmModalVisible}
        title="Confirm Logout"
        message="Are you sure you want to log out?"
        onCancel={() => setIsLogoutConfirmModalVisible(false)}
        onConfirm={handleConfirmLogout}
        confirmButtonText="Logout"
      />

      {/* Delete Chat Confirmation Modal */}
      <ConfirmationModal
        isVisible={isDeleteConfirmModalVisible}
        title="Delete Chat"
        message={`Are you sure you want to permanently delete "${chatToDelete?.name || 'this chat'}"? This action cannot be undone.`}
        onCancel={handleCancelDelete}
        onConfirm={handleConfirmDelete}
        confirmButtonText="Delete"
      />
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    borderTopLeftRadius: 20,
    borderBottomLeftRadius: 20,
    overflow: 'hidden',
  },
  overlay: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(255, 243, 217, 0.85)', zIndex: 0 },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    alignItems: 'flex-end',
  },
  sidebarContainer: {
    width: SIDEBAR_WIDTH,
    height: '100%',
    backgroundColor: '#f0f0f0',
    paddingTop: Platform.OS === 'android' ? 25 : 40,
    borderTopLeftRadius: 20,
    borderBottomLeftRadius: 20,
  },
  sidebarHeader: {
    flexDirection: 'row-reverse',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 15,
    paddingVertical: 15,
    borderBottomWidth: 1,
    borderBottomColor: '#ccc',
  },
  sidebarTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
  },
  closeButton: {
    padding: 5,
  },
  newChatButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#007BFF',
    paddingVertical: 12,
    paddingHorizontal: 15,
    borderRadius: 8,
    marginHorizontal: 15,
    marginVertical: 15,
    elevation: 2,
  },
  newChatIcon: {
    marginRight: 10,
  },
  newChatButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  chatList: {
    flex: 1,
  },
  chatItemContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  chatItem: {
    flex: 1,
    paddingVertical: 12,
    paddingHorizontal: 20,
  },
  activeChatItem: {
    backgroundColor: '#007BFF20',
  },
  chatItemText: {
    fontSize: 16,
    color: '#333',
  },
  activeChatItemText: {
    fontWeight: 'bold',
    color: '#0056b3',
  },
  deleteIcon: {
    padding: 10,
    marginRight: 5,
  },
  emptyListText: {
    textAlign: 'center',
    marginTop: 20,
    color: '#777',
    fontSize: 15,
  },
  logoutButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 15,
    paddingHorizontal: 20,
    borderTopWidth: 1,
    borderTopColor: '#ccc',
    backgroundColor: 'rgba(255, 243, 217, 0.95)'
  },
  logoutIcon: {
    marginRight: 10,
  },
  logoutButtonText: {
    fontSize: 16,
    color: '#333',
    fontWeight: '600',
  },
});

export default Sidebar;