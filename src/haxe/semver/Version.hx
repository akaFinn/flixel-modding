package haxe.semver;

using StringTools;

/**
 * Typedef holding the raw version data
 */
typedef VersionData = 
{
    var major:Int;
    var minor:Int;
    var patch:Int;

    var prerelease:Array<String>;
    var build:Array<String>;
}

/**
 * Semantic Version class
 * Allows implicit creation from string, comparisons, and increment helpers
 */
abstract Version(VersionData) 
{
    public static final FORMAT:EReg = ~/^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+([0-9A-Za-z.-]+))?$/;

    /**
     * Creates a new Version from numbers, prerelease, and build identifiers
     */
    public inline function new(major:Int, minor:Int, patch:Int, pre:Array<String>, build:Array<String>)
    { 
        this = 
        { 
            major: major,
            minor: minor,
            patch: patch,
            prerelease: pre,
            build: build,
        };
    }

    /**
     * Parses a SemVer string into a Version
     */
    @:from
    public static function fromString(text:String):Version
    { 
        return Version.parse(text);
    }

    /**
     * Parses a SemVer string into a Version
     * Throws if the string is not strictly valid
     */
    public static function parse(text:String):Version
    { 
        if (!FORMAT.match(text))
            throw 'Invalid semantic version "$text"';

        var major = Std.parseInt(FORMAT.matched(1));
        var minor = Std.parseInt(FORMAT.matched(2));
        var patch = Std.parseInt(FORMAT.matched(3));

        var pre:Array<String> = parseIdentifiers(FORMAT.matched(4));
        var build:Array<String> = parseIdentifiers(FORMAT.matched(5));

        return new Version(major, minor, patch, pre, build);
    }

    /**
     * Converts Version back to a SemVer string
     */
    @:to
    public function toString():String
    { 
        var base = '${this.major}.${this.minor}.${this.patch}';

        if (this.prerelease.length > 0)
            base += "-" + this.prerelease.join(".");

        if (this.build.length > 0)
            base += "+" + this.build.join(".");

        return base;
    }

    /**
     * Returns true if this version has a prerelease
     */
    public inline function hasPrerelease():Bool
    { 
        return this.prerelease.length > 0;
    }

    /**
     * Returns true if this version has build metadata
     */
    public inline function hasBuild():Bool
    { 
        return this.build.length > 0;
    }

    /**
     * Returns a new Version with major incremented
     */
    public function nextMajor():Version
    { 
        return new Version(major + 1, 0, 0, [], []);
    }

    /**
     * Returns a new Version with minor incremented
     */
    public function nextMinor():Version
    { 
        return new Version(major, minor + 1, 0, [], []);
    }

    /**
     * Returns a new Version with patch incremented
     */
    public function nextPatch():Version
    { 
        return new Version(major, minor, patch + 1, [], []);
    }

    /**
     * Returns a new Version with next prerelease numeric identifier
     */
    public function nextPre():Version
    { 
        return new Version(major, minor, patch, incrementIdentifiers(prerelease), []);
    }

    /**
     * Returns a new Version with next build numeric identifier
     */
    public function nextBuild():Version
    { 
        return new Version(major, minor, patch, prerelease, incrementIdentifiers(build));
    }

    /**
     * Returns a new Version with a specific prerelease string
     */
    public function withPre(pre:String, ?build:String):Version
    { 
        return new Version(major, minor, patch, parseIdentifiers(pre), parseIdentifiers(build));
    }

    /**
     * Returns a new Version with a specific build string
     */
    public function withBuild(build:String):Version
    { 
        return new Version(major, minor, patch, prerelease, parseIdentifiers(build));
    }

    /**
     * Compares this Version with another
     * Returns -1 if this < other, 0 if equal, 1 if this > other
     */
    public function compare(other:Version):Int
    { 
        for (k in ["major","minor","patch"])
        { 
            var a = Reflect.field(this, k);
            var b = Reflect.field(other, k);
            if (a < b) return -1;
            if (a > b) return 1;
        }

        var aPre = prerelease;
        var bPre = other.prerelease;

        if (aPre.length == 0 && bPre.length == 0) return 0;
        if (aPre.length == 0) return 1;
        if (bPre.length == 0) return -1;

        var len = Math.max(aPre.length, bPre.length);
        for (i in 0...Std.int(len))
        { 
            var aa = i < aPre.length ? aPre[i] : "";
            var bb = i < bPre.length ? bPre[i] : "";

            var ai = Std.parseInt(aa);
            var bi = Std.parseInt(bb);
            var aNum = !Math.isNaN(ai);
            var bNum = !Math.isNaN(bi);

            if (aNum && bNum)
            { 
                if (ai < bi) return -1;
                if (ai > bi) return 1;
            }
            else
            { 
                if (aa < bb) return -1;
                if (aa > bb) return 1;
            }
        }
        return 0;
    }

    /**
     * Returns true if versions are equal
     */
    public inline function equals(other:Version):Bool
    { 
        return compare(other) == 0;
    }

    /**
     * Returns true if versions are different
     */
    public inline function different(other:Version):Bool
    { 
        return !equals(other);
    }

    /**
     * Returns true if this > other
     */
    public inline function greaterThan(other:Version):Bool
    { 
        return compare(other) > 0;
    }

    /**
     * Returns true if this >= other
     */
    public inline function greaterThanOrEqual(other:Version):Bool
    { 
        return compare(other) >= 0;
    }

    /**
     * Returns true if this < other
     */
    public inline function lessThan(other:Version):Bool
    { 
        return compare(other) < 0;
    }

    /**
     * Returns true if this <= other
     */
    public inline function lessThanOrEqual(other:Version):Bool
    { 
        return compare(other) <= 0;
    }

    /**
     * Parses dot-separated identifiers into Array<String>
     */
    private static function parseIdentifiers(s:String):Array<String>
    { 
        return (s == null ? [] : s.split(".").map(sanitize)).filter(function(v) return v != "");
    }

    /**
     * Increment the last numeric identifier in the array
     */
    private static function incrementIdentifiers(ids:Array<String>):Array<String>
    { 
        var copy = ids.copy();
        var i = copy.length - 1;

        while (i >= 0)
        { 
            var n = Std.parseInt(copy[i]);

            if (!Math.isNaN(n))
            { 
                copy[i] = Std.string(n + 1);
                return copy;
            }

            i--;
        }

        copy.push("1");
        return copy;
    }

    /**
     * Sanitizes an identifier according to SemVer
     */
    public static function sanitize(s:String):String
    { 
        return ~/[^0-9A-Za-z-]/g.replace(s,"");
    }

    /**
     * Returns true if the given version is a development version
     */
    public static function isDevelopment(version:Version):Bool
    {
        if (!version.hasPrerelease())
            return false;

        for (pre in version.prerelease)
        { 
            var lower = pre.toLowerCase();
            if (lower == "alpha" || lower == "beta" || lower == "rc")
                return true;
        }

        return false;
    }

    /**
     * Placeholder for version range parsing (`^1.2.3`, `~2.0.0`)
     */
    public function satisfies(rule:String):Bool
    { 
        return false;
    }

    public var major(get, never):Int;
    inline function get_major() return this.major;

    public var minor(get, never):Int;
    inline function get_minor() return this.minor;

    public var patch(get, never):Int;
    inline function get_patch() return this.patch;

    public var prerelease(get, never):Array<String>;
    inline function get_prerelease() return this.prerelease;

    public var build(get, never):Array<String>;
    inline function get_build() return this.build;
}
