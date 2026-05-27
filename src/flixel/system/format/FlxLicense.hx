package flixel.system.format;

import flixel.util.FlxStringUtil;

/**
 * Holds a collection of common software licenses with their
 * full human-readable name and SPDX keyword.
 * 
 * Each license is represented as a `FlxLicense` containing:
 * - `name`: The official full name of the license.
 * - `keyword`: The standardized SPDX identifier.
 * 
 * This class provides static access to these licenses for
 * easy reference throughout Flixel or modding projects.
 */
class FlxLicense
{
    /**
     * Academic Free License v3.0
     * 
     * SPDX keyword: AFL-3.0
     */
    public static final AFL_3_0:FlxLicense = new FlxLicense("Academic Free License v3.0", "AFL-3.0");

    /**
     * Apache License 2.0
     * 
     * SPDX keyword: Apache-2.0
     */
    public static final APACHE_2_0:FlxLicense = new FlxLicense("Apache license 2.0", "Apache-2.0");

    /**
     * Artistic License 2.0
     * 
     * SPDX keyword: Artistic-2.0
     */
    public static final ARTISTIC_2_0:FlxLicense = new FlxLicense("Artistic license 2.0", "Artistic-2.0");

    /**
     * Boost Software License 1.0
     * 
     * SPDX keyword: BSL-1.0
     */
    public static final BSL_1_0:FlxLicense = new FlxLicense("Boost Software License 1.0", "BSL-1.0");

    /**
     * BSD 2-clause "Simplified" license
     * 
     * SPDX keyword: BSD-2-Clause
     */
    public static final BSD_2_CLAUSE:FlxLicense = new FlxLicense("BSD 2-clause \"Simplified\" license", "BSD-2-Clause");

    /**
     * BSD 3-clause "New" or "Revised" license
     * 
     * SPDX keyword: BSD-3-Clause
     */
    public static final BSD_3_CLAUSE:FlxLicense = new FlxLicense("BSD 3-clause \"New\" or \"Revised\" license", "BSD-3-Clause");

    /**
     * BSD 3-clause Clear license
     * 
     * SPDX keyword: BSD-3-Clause-Clear
     */
    public static final BSD_3_CLAUSE_CLEAR:FlxLicense = new FlxLicense("BSD 3-clause Clear license", "BSD-3-Clause-Clear");

    /**
     * BSD 4-clause "Original" or "Old" license
     * 
     * SPDX keyword: BSD-4-Clause
     */
    public static final BSD_4_CLAUSE:FlxLicense = new FlxLicense("BSD 4-clause \"Original\" or \"Old\" license", "BSD-4-Clause");

    /**
     * BSD Zero-Clause license
     * 
     * SPDX keyword: 0BSD
     */
    public static final ZERO_BSD:FlxLicense = new FlxLicense("BSD Zero-Clause license", "0BSD");

    /**
     * Creative Commons license family
     * 
     * SPDX keyword: CC
     */
    public static final CC:FlxLicense = new FlxLicense("Creative Commons license family", "CC");

    /**
     * Creative Commons Zero v1.0 Universal
     * 
     * SPDX keyword: CC0-1.0
     */
    public static final CC0_1_0:FlxLicense = new FlxLicense("Creative Commons Zero v1.0 Universal", "CC0-1.0");

    /**
     * Creative Commons Attribution 4.0
     * 
     * SPDX keyword: CC-BY-4.0
     */
    public static final CC_BY_4_0:FlxLicense = new FlxLicense("Creative Commons Attribution 4.0", "CC-BY-4.0");

    /**
     * Creative Commons Attribution ShareAlike 4.0
     * 
     * SPDX keyword: CC-BY-SA-4.0
     */
    public static final CC_BY_SA_4_0:FlxLicense = new FlxLicense("Creative Commons Attribution ShareAlike 4.0", "CC-BY-SA-4.0");

    /**
     * Do What The F*ck You Want To Public License
     * 
     * SPDX keyword: WTFPL
     */
    public static final WTFPL:FlxLicense = new FlxLicense("Do What The F*ck You Want To Public License", "WTFPL");

    /**
     * Educational Community License v2.0
     * 
     * SPDX keyword: ECL-2.0
     */
    public static final ECL_2_0:FlxLicense = new FlxLicense("Educational Community License v2.0", "ECL-2.0");

    /**
     * Eclipse Public License 1.0
     * 
     * SPDX keyword: EPL-1.0
     */
    public static final EPL_1_0:FlxLicense = new FlxLicense("Eclipse Public License 1.0", "EPL-1.0");

    /**
     * Eclipse Public License 2.0
     * 
     * SPDX keyword: EPL-2.0
     */
    public static final EPL_2_0:FlxLicense = new FlxLicense("Eclipse Public License 2.0", "EPL-2.0");

    /**
     * European Union Public License 1.1
     * 
     * SPDX keyword: EUPL-1.1
     */
    public static final EUPL_1_1:FlxLicense = new FlxLicense("European Union Public License 1.1", "EUPL-1.1");

    /**
     * GNU Affero General Public License v3.0
     * 
     * SPDX keyword: AGPL-3.0
     */
    public static final AGPL_3_0:FlxLicense = new FlxLicense("GNU Affero General Public License v3.0", "AGPL-3.0");

    /**
     * GNU General Public License family
     * 
     * SPDX keyword: GPL
     */
    public static final GPL:FlxLicense = new FlxLicense("GNU General Public License family", "GPL");

    /**
     * GNU General Public License v2.0
     * 
     * SPDX keyword: GPL-2.0
     */
    public static final GPL_2_0:FlxLicense = new FlxLicense("GNU General Public License v2.0", "GPL-2.0");

    /**
     * GNU General Public License v3.0
     * 
     * SPDX keyword: GPL-3.0
     */
    public static final GPL_3_0:FlxLicense = new FlxLicense("GNU General Public License v3.0", "GPL-3.0");

    /**
     * GNU Lesser General Public License family
     * 
     * SPDX keyword: LGPL
     */
    public static final LGPL:FlxLicense = new FlxLicense("GNU Lesser General Public License family", "LGPL");

    /**
     * GNU Lesser General Public License v2.1
     * 
     * SPDX keyword: LGPL-2.1
     */
    public static final LGPL_2_1:FlxLicense = new FlxLicense("GNU Lesser General Public License v2.1", "LGPL-2.1");

    /**
     * GNU Lesser General Public License v3.0
     * 
     * SPDX keyword: LGPL-3.0
     */
    public static final LGPL_3_0:FlxLicense = new FlxLicense("GNU Lesser General Public License v3.0", "LGPL-3.0");

    /**
     * ISC License
     * 
     * SPDX keyword: ISC
     */
    public static final ISC:FlxLicense = new FlxLicense("ISC", "ISC");

    /**
     * LaTeX Project Public License v1.3c
     * 
     * SPDX keyword: LPPL-1.3c
     */
    public static final LPPL_1_3C:FlxLicense = new FlxLicense("LaTeX Project Public License v1.3c", "LPPL-1.3c");

    /**
     * Microsoft Public License
     * 
     * SPDX keyword: MS-PL
     */
    public static final MS_PL:FlxLicense = new FlxLicense("Microsoft Public License", "MS-PL");

    /**
     * MIT License
     * 
     * SPDX keyword: MIT
     */
    public static final MIT:FlxLicense = new FlxLicense("MIT", "MIT");

    /**
     * Mozilla Public License 2.0
     * 
     * SPDX keyword: MPL-2.0
     */
    public static final MPL_2_0:FlxLicense = new FlxLicense("Mozilla Public License 2.0", "MPL-2.0");

    /**
     * Open Software License 3.0
     * 
     * SPDX keyword: OSL-3.0
     */
    public static final OSL_3_0:FlxLicense = new FlxLicense("Open Software License 3.0", "OSL-3.0");

    /**
     * PostgreSQL License
     * 
     * SPDX keyword: PostgreSQL
     */
    public static final POSTGRESQL:FlxLicense = new FlxLicense("PostgreSQL License", "PostgreSQL");

    /**
     * SIL Open Font License 1.1
     * 
     * SPDX keyword: OFL-1.1
     */
    public static final OFL_1_1:FlxLicense = new FlxLicense("SIL Open Font License 1.1", "OFL-1.1");

    /**
     * University of Illinois/NCSA Open Source License
     * 
     * SPDX keyword: NCSA
     */
    public static final NCSA:FlxLicense = new FlxLicense("University of Illinois/NCSA Open Source License", "NCSA");

    /**
     * The Unlicense
     * 
     * SPDX keyword: Unlicense
     */
    public static final UNLICENSE:FlxLicense = new FlxLicense("The Unlicense", "Unlicense");

    /**
     * zLib License
     * 
     * SPDX keyword: Zlib
     */
    public static final ZLIB:FlxLicense = new FlxLicense("zLib License", "Zlib");

    /**
     * Retrieves a license entry based on its human-readable name.
     * 
     * Iterates through all known licenses and compares the `name` field.
     * 
     * If no matching license is found, a warning is logged and `null` is returned.
     * 
     * @param name   The human-readable name of the license to look up.
     * @return       The matching `FlxLicense` or `null` if not found.
     */
    public static function getFromName(name:String):FlxLicense
    {
        for (licenseEntry in FlxLicense.listAllLicenses())
        {
            if (licenseEntry.name == name)
            {
                return licenseEntry;
            }
        }

        FlxG.log.warn('Failed to get License by the name "$name"');
        return null;
    }

    /**
     * Retrieves a license entry based on its standardized SPDX keyword.
     * 
     * Iterates through all known licenses and compares the `keyword` field.
     * 
     * If no matching license is found, a warning is logged and `null` is returned.
     * 
     * @param keyword   The SPDX keyword of the license to look up.
     * @return          The matching `FlxLicense` or `null` if not found.
     */
    public static function getFromKeyword(keyword:String):FlxLicense
    {
        for (licenseEntry in FlxLicense.listAllLicenses())
        {
            if (licenseEntry.keyword == keyword)
            {
                return licenseEntry;
            }
        }

        FlxG.log.warn('Failed to get License by the keyword "$keyword"');
        return null;
    }

    /**
     * Returns an array of all predefined license entries.
     * 
     * This list includes every static inline license defined in `FlxLicense`.
     * It is used by lookup functions and for iteration over all supported licenses.
     * 
     * @return   An array of `FlxLicense` representing all known licenses.
     */
    public static function listAllLicenses():Array<FlxLicense>
    {
        return [
            AFL_3_0, APACHE_2_0, ARTISTIC_2_0, AGPL_3_0, BSL_1_0,
            BSD_2_CLAUSE, BSD_3_CLAUSE, BSD_3_CLAUSE_CLEAR, BSD_4_CLAUSE,
            CC, CC0_1_0, CC_BY_4_0, CC_BY_SA_4_0, ECL_2_0,
            EPL_1_0, EPL_2_0, EUPL_1_1, GPL, GPL_2_0, GPL_3_0,
            ISC, LGPL, LGPL_2_1, LGPL_3_0, LPPL_1_3C, MS_PL,
            MIT, MPL_2_0, NCSA, OSL_3_0, POSTGRESQL,
            UNLICENSE, WTFPL, ZERO_BSD, ZLIB
        ];
    }

    /**
     * Human-readable name of the license.
     * 
     * Example: "MIT", "Apache License 2.0", "Creative Commons Attribution 4.0".
     */
    public var name:String;

    /**
     * Standardized SPDX keyword for the license.
     * 
     * Example: "MIT", "Apache-2.0", "CC-BY-4.0".
     */
    public var keyword:String;

    /**
     * Creates a new `FlxLicense` instance.
     * 
     * Assigns the provided human-readable `name` and the
     * standardized SPDX `keyword` to this entry.
     * 
     * @param name     The full, human-readable license name.
     * @param keyword  The official SPDX identifier for the license.
     */
    public function new(name:String, keyword:String)
    {
        this.name = name;
        this.keyword = keyword;
    }

    /**
     * Converts to string.
     * 
     * @return String
     */
    private function toString():String
    {
        return FlxStringUtil.getDebugString([
            LabelValuePair.weak("name", this.name), 
            LabelValuePair.weak("keyword", this.keyword)
        ]);
    }
}