/*
Copyright (c) 2021-2023 Timur Gafarov

Boost Software License - Version 1.0 - August 17th, 2003
Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module dgpu.core.locale;

import std.conv;
import std.format;
import std.process;

version(Windows)
{
    extern(Windows) int GetLocaleInfoW(
        in uint Locale,
        in uint LCType,
        wchar* lpLCData,
        in int cchData
    );
    
    extern(Windows) int GetLocaleInfoA(
        in uint Locale,
        in uint LCType,
        char* lpLCData,
        in int cchData
    );
    
    enum uint LOCALE_USER_DEFAULT = 0x0400;
    enum uint LOCALE_SISO639LANGNAME = 0x59;
    enum uint LOCALE_SISO3166CTRYNAME = 0x5a;
}

private string syslocale = "en_US";
static this()
{
    // TODO: don't use GC
    version(Windows)
    {
        string getLanguage()
        {
            char[16] str;
            GetLocaleInfoA(LOCALE_USER_DEFAULT, LOCALE_SISO639LANGNAME, str.ptr, str.length);
            return str.ptr.to!string;
        }
        
        string getCountry()
        {
            char[16] str;
            GetLocaleInfoA(LOCALE_USER_DEFAULT, LOCALE_SISO3166CTRYNAME, str.ptr, str.length);
            return str.ptr.to!string;
        }
    
        string lang = getLanguage();
        string country = getCountry();
        syslocale = format("%s_%s", lang, country);
    }
    else version(Posix)
    {
        string lang = environment.get("LANG", "en_US.utf8");
        string locale, encoding;
        formattedRead(lang, "%s.%s", &locale, &encoding);
        syslocale = locale;
    }
}

string systemLocale()
{
    return syslocale;
}
