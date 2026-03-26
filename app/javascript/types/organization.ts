export type Organization = {
    id?: string | number
    name: string
    subdomain: string
    logo_path?: string
    cover_path?: string
    users_count: number
    plan: OrganizationPlans
}

export enum OrganizationPlans {
  FREE = 'free',
  PRO = 'pro',
  ENTERPRISE = 'enterprise',
}