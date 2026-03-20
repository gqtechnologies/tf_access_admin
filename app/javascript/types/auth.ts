import type { User } from '@/types/user'
export type SharedProps = {
    auth: {
      user: User | null;
    };
  };