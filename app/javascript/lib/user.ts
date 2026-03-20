import { User } from "@/types/user"

export const getUserFallback = (user: User) => {
    return getStringFallback(user.name)
}


export const getStringFallback = (string: string) => {
    return string.charAt(0) + string.split(' ').pop()?.charAt(0)
}