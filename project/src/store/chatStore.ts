import { create } from 'zustand';
import { ChatState, Message } from '../types/chat';

export const useChatStore = create<ChatState>((set) => ({
  messages: [],
  isTyping: false,
  addMessage: (content, sender) => {
    const newMessage: Message = {
      id: Date.now().toString(),
      content,
      sender,
      timestamp: new Date(),
    };
    set((state) => ({
      messages: [...state.messages, newMessage],
    }));
  },
  setIsTyping: (typing) => set({ isTyping: typing }),
}));