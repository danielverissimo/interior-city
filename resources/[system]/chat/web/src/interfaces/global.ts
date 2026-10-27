export interface IMessage {
  icon?: string;
  title?: string;
  category?: string;
  message: string;
  
  color: string;
  boxColor: string;
  background?: string;

  created_at?: Date;
}