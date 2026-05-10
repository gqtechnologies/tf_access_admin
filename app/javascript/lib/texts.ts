export const showPartOfText = (text?: string, maxLength: number = 50) => {
    if (!text || text.length <= maxLength) {
        return text
    }
    return text.substring(0, maxLength) + "..."
}

export const formatCurrency = (amount: number, currency: string, locale: string = 'es-CL') => {
    return new Intl.NumberFormat(locale, { style: 'currency', currency: currency }).format(amount)
}