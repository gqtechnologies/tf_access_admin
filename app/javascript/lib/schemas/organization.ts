import { z } from 'zod'
import { OrganizationPlans } from '@/types/organization'

const plansTypes = Object.values(OrganizationPlans) as [string, ...string[]]

export const organizationValidationKeys = {
  name_required: 'admin.organizations.validations.name_required',
  name_max: 'admin.organizations.validations.name_max',
  subdomain_required: 'admin.organizations.validations.subdomain_required',
  subdomain_invalid: 'admin.organizations.validations.subdomain_invalid',
  subdomain_max: 'admin.organizations.validations.subdomain_max',
  subdomain_min: 'admin.organizations.validations.subdomain_min',
  subdomain_no_whitespace: 'admin.organizations.validations.subdomain_no_whitespace',
  plan_required: 'admin.organizations.validations.plan_required',
  plan_invalid: 'admin.organizations.validations.plan_invalid',
} as const

export const organizationSubdomainMin = 3
export const nameMin = 1
export const nameMax = 255
export const organizationSubdomainMax = 8
export const organizationPlanSchema = z.enum(plansTypes, { message: organizationValidationKeys.plan_invalid })

export const organizationSubdomainSchema = z.string().min(organizationSubdomainMin, organizationValidationKeys.subdomain_min)
.max(organizationSubdomainMax, organizationValidationKeys.subdomain_max)
.regex(/^\S+$/, { message: organizationValidationKeys.subdomain_no_whitespace })
.regex(/^[a-z][a-z0-9-]*$/, { message: organizationValidationKeys.subdomain_invalid });

export const organizationSchema = z.object({
  name: z.string().min(nameMin, organizationValidationKeys.name_required)
  .max(nameMax, organizationValidationKeys.name_max),
  plan: organizationPlanSchema,
  subdomain: organizationSubdomainSchema,
  cover: z.instanceof(File).nullable(),
  logo: z.instanceof(File).nullable(),
  remove_cover: z.boolean().default(false),
  remove_logo: z.boolean().default(false),
});

export type OrganizationSchema = z.infer<typeof organizationSchema>;