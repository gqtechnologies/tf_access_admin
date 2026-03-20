export type User = {
    id?: string | number
    avatar_path?: string | null | undefined
    avatar_filename?: string | null | undefined
    name: string
    dni: string
    email: string
    language: string
    role: string
}