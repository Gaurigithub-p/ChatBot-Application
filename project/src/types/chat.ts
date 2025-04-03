export interface Message {
  id: string;
  content: string;
  sender: 'user' | 'bot';
  timestamp: Date;
}

export interface ChatState {
  messages: Message[];
  addMessage: (content: string, sender: 'user' | 'bot') => void;
  isTyping: boolean;
  setIsTyping: (typing: boolean) => void;
}