stock void UTIL_LogToFile(const char[] name, const char[] mag, any ...)
{
	char format[256], file[PLATFORM_MAX_PATH];
	VFormat(format, sizeof(format), mag, 3);
	FormatTime(file, sizeof(file), "%Y%m"); // "%Y%m%d"
	BuildPath(Path_SM, file, sizeof(file), "logs/%s_%s.log", name, file);
	LogToFileEx(file, "%s", format);
}