local TimeKeeper = {}

-------------------------------------------------------------------------------------------------------------------
local TimeFormat: string = `D MMMM YYYY hh:mm:ss A` -- add :SSS after :ss for milliseconds

-------------------------------------------------------------------------------------------------------------------
TimeKeeper.PreciseSinceEnvironmentStart = os.clock
TimeKeeper.GetTimeDifferenceFromUNIX = os.difftime

-------------------------------------------------------------------------------------------------------------------
function TimeKeeper.GetServerTimeNow()
	return workspace:GetServerTimeNow()
end

-------------------------------------------------------------------------------------------------------------------
function TimeKeeper.GetNowAsUNIX(Level: number)
	return DateTime.now()[`UnixTimestamp{Level == 1 and "Millis" or ""}`]
end

-------------------------------------------------------------------------------------------------------------------
function TimeKeeper.GetTimeDataAsUTCFromUNIX(Time: number)
	return DateTime.fromUnixTimestamp(Time):ToUniversalTime()
end

-------------------------------------------------------------------------------------------------------------------
function TimeKeeper.GetTimeDataAsUTCFromNow()
	return DateTime.now():ToUniversalTime()
end

-------------------------------------------------------------------------------------------------------------------
function TimeKeeper.GetTimeDataAsLocalFromUNIX(Time: number)
	return DateTime.fromUnixTimestamp(Time):ToLocalTime()
end

-------------------------------------------------------------------------------------------------------------------
function TimeKeeper.GetTimeDataAsLocalFromNow()
	return DateTime.now():ToLocalTime()
end

-------------------------------------------------------------------------------------------------------------------
function TimeKeeper.DisplayTimeAsUTCFromUNIX(Time: number, Locale: string): string
	return DateTime.fromUnixTimestamp(Time):FormatUniversalTime(TimeFormat, Locale or `en-us`)
end

-------------------------------------------------------------------------------------------------------------------
function TimeKeeper.DisplayNowAsUTC(Locale: string): string
	return DateTime.now():FormatUniversalTime(TimeFormat, Locale or `en-us`)
end

-------------------------------------------------------------------------------------------------------------------
function TimeKeeper.DisplayTimeAsLocalFromUNIX(Time: number, Locale: string): string
	return DateTime.fromUnixTimestamp(Time):FormatLocalTime(TimeFormat, Locale or `en-us`)
end

-------------------------------------------------------------------------------------------------------------------
function TimeKeeper.DisplayNowAsLocal(Locale: string): string
	return DateTime.now():FormatLocalTime(TimeFormat, Locale or `en-us`)
end

-------------------------------------------------------------------------------------------------------------------
return TimeKeeper
