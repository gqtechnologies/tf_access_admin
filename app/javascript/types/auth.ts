import type { User } from '@/types/user'

export type FeatureItem = {
  key: string;
  url: string;
}

export type SharedProps = {
    auth: {
      user: User | null;
      features: FeatureItem[];
    };
  };