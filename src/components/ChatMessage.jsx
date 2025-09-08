// src/components/ChatMessage.jsx
import React, { useState, useEffect, forwardRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  Image,
  Animated,
  Easing,
} from 'react-native';

// Typing indicator (3 bouncing dots)
const TypingIndicator = () => {
  const dot1 = new Animated.Value(0);
  const dot2 = new Animated.Value(0);
  const dot3 = new Animated.Value(0);

  useEffect(() => {
    const animateDot = (animatedValue, delay) =>
      Animated.loop(
        Animated.sequence([
          Animated.delay(delay),
          Animated.timing(animatedValue, {
            toValue: 1,
            duration: 300,
            easing: Easing.inOut(Easing.ease),
            useNativeDriver: true,
          }),
          Animated.timing(animatedValue, {
            toValue: 0,
            duration: 300,
            easing: Easing.inOut(Easing.ease),
            useNativeDriver: true,
          }),
        ])
      );

    const a1 = animateDot(dot1, 0);
    const a2 = animateDot(dot2, 150);
    const a3 = animateDot(dot3, 300);

    a1.start();
    a2.start();
    a3.start();

    return () => {
      a1.stop();
      a2.stop();
      a3.stop();
    };
  }, []);

  const dotStyle = (value) => ({
    opacity: value.interpolate({
      inputRange: [0, 1],
      outputRange: [0.4, 1],
    }),
    transform: [
      {
        translateY: value.interpolate({
          inputRange: [0, 1],
          outputRange: [0, -8], // ⬅️ Adjust this height to change bounce
        }),
      },
      {
        scale: value.interpolate({
          inputRange: [0, 1],
          outputRange: [0.8, 1.2],
        }),
      },
    ],
  });

  return (
    <View style={styles.typingContainer}>
      <Animated.View style={[styles.typingDot, dotStyle(dot1)]} />
      <Animated.View style={[styles.typingDot, dotStyle(dot2)]} />
      <Animated.View style={[styles.typingDot, dotStyle(dot3)]} />
    </View>
  );
};
// AI message with typing animation
const AiMessageWithTyping = ({ fullText, onAnimationComplete }) => {
  const [displayed, setDisplayed] = useState('');
  const speed = 0.3; // 0.3s per character

  useEffect(() => {
    if (displayed.length < fullText.length) {
      const id = setTimeout(() => {
        setDisplayed(fullText.substr(0, displayed.length + 1));
      }, speed);
      return () => clearTimeout(id);
    } else {
      onAnimationComplete && onAnimationComplete();
    }
  }, [displayed, fullText, onAnimationComplete]);

  return (
    <View style={[styles.messageBubble, styles.aiBubble]}>
      <Image
        source={require('../../assets/AivaNobg.png')}
        style={styles.aiAvatar}
      />
      <View style={styles.aiMessageText}>
        <Text style={styles.messageTextContent}>
          {displayed}
          {displayed.length < fullText.length && (
            <Text style={styles.cursor}>|</Text>
          )}
        </Text>
      </View>
    </View>
  );
};

// Main component
const ChatMessages = forwardRef(
  ({ messages, onLastAiMessageTyped, lastAiMessageIdForOAuth }, ref) => {
    const [typingId, setTypingId] = useState(null);
    const [doneSet, setDoneSet] = useState(new Set());

    useEffect(() => {
      if (messages.length) {
        const last = messages[messages.length - 1];
        if (last.sender === 'ai' && !doneSet.has(last.id)) {
          setTypingId(last.id);
        } else {
          setTypingId(null);
        }
      }
    }, [messages, doneSet]);

    const onComplete = (id) => {
      setDoneSet((prev) => new Set(prev).add(id));
      setTypingId(null);
      if (id === lastAiMessageIdForOAuth && onLastAiMessageTyped) {
        onLastAiMessageTyped();
      }
    };

    const renderItem = ({ item, index }) => {
      if (item.isTyping) {
        return (
          <View style={[styles.messageBubble, styles.aiBubble]}>
            <Image
              source={require('../../assets/AivaNobg.png')}
              style={styles.aiAvatar}
            />
            <TypingIndicator />
          </View>
        );
      }

      if (item.sender === 'ai') {
        if (item.id === typingId && !doneSet.has(item.id)) {
          return (
            <AiMessageWithTyping
              fullText={item.text}
              onAnimationComplete={() => onComplete(item.id)}
            />
          );
        }
        return (
          <View style={[styles.messageBubble, styles.aiBubble]}>
            <Image
              source={require('../../assets/AivaNobg.png')}
              style={styles.aiAvatar}
            />
            <View style={styles.aiMessageText}>
              <Text style={styles.messageTextContent}>{item.text}</Text>
            </View>
          </View>
        );
      }

      return (
        <View style={[styles.messageBubble, styles.userBubble]}>
          <Text style={styles.userMessageText}>{item.text}</Text>
        </View>
      );
    };

    const shouldShowTypingIndicator =
      messages.length > 0 &&
      messages[messages.length - 1].sender === 'user';

    return (
      <View style={{ flex: 1 }}>
        <FlatList
          ref={ref}
          data={
            messages.length > 0 && messages[messages.length - 1].sender === 'user'
              ? [...messages, { id: 'typing-indicator', sender: 'ai', isTyping: true }]
              : messages
          }
          renderItem={renderItem}
          keyExtractor={(item) => item.id || `${item.timestamp}`}
          contentContainerStyle={styles.listContentContainer}
          onContentSizeChange={() =>
            ref?.current?.scrollToEnd({ animated: true })
          }
          onLayout={() => ref?.current?.scrollToEnd({ animated: true })}
        />

      </View>
    );
  }
);

const styles = StyleSheet.create({
  listContentContainer: {
    paddingVertical: 10,
    paddingHorizontal: 10,
  },
  messageBubble: {
    maxWidth: '85%',
    paddingVertical: 10,
    paddingHorizontal: 15,
    borderRadius: 20,
    marginBottom: 8,
    flexDirection: 'row',
    alignItems: 'flex-end',
  },
  userBubble: {
    backgroundColor: '#007AFF',
    alignSelf: 'flex-end',
    borderBottomRightRadius: 5,
  },
  aiBubble: {
    backgroundColor: 'transparent',
    alignSelf: 'flex-start',
  },
  userMessageText: {
    fontSize: 16,
    color: '#fff',
  },
  aiMessageText: {
    backgroundColor: 'rgba(255,255,255,0.9)',
    padding: 12,
    borderRadius: 20,
    borderBottomLeftRadius: 5,
    flexShrink: 1,
  },
  messageTextContent: {
    fontSize: 16,
    color: '#000',
  },
  cursor: {
    color: '#000',
    fontWeight: 'bold',
  },
  aiAvatar: {
    width: 30,
    height: 30,
    borderRadius: 15,
    marginRight: 8,
    alignSelf: 'flex-end',
  },
  typingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginLeft: 16,
    paddingBottom: 10,
  },
  typingDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: 'black',
    marginHorizontal: 3,
  },
});

export default ChatMessages;
