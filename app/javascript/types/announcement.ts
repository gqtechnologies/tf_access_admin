export type AnnouncementStatus = 'draft' | 'published' | 'archived'

export type AdminAnnouncement = {
  id: string
  title: string
  content: string
  category: string | null
  priority: string
  status: AnnouncementStatus
  requires_acknowledgement: boolean
  published_at: string | null
  expires_at: string | null
  created_at: string
  author_name: string | null
  read_count: number
  acknowledged_count: number
}

export type AnnouncementFormValues = {
  title: string
  content: string
  category: string
  priority: string
  requires_acknowledgement: boolean
  expires_at: string
}
