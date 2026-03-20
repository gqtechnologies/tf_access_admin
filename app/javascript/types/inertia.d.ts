import { SharedProps } from './auth';

declare module '@inertiajs/core' {
  interface PageProps extends SharedProps {}
}