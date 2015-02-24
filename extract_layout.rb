# Return an array of hashes of ranges defining column locations for each record type
def extract_layout
  { household: {
    ACSYR: 2..5,
    SERIAL: 8..15,
    HHWT: 16..25,
    HHTYPE: 26..26,
    STATEICP: 27..28,
    METAREA: 29..31,
    METAREAD: 32..35,
    CITY: 36..39,
    CITYPOP: 40..44,
    GQ: 45..45,
    OWNERSHP: 46..46,
    OWNERSHPD: 47..48,
    MORTGAGE: 49..49,
    MORTGAG2: 50..50,
    ACREHOUS: 51..51,
    MORTAMT1: 52..56,
    MORTAMT2: 57..60,
    TAXINCL: 61..61,
    INSINCL: 62..62,
    PROPINSR: 63..66,
    OWNCOST: 67..71,
    RENT: 72..75,
    RENTGRS: 76..79,
    CONDOFEE: 80..83,
    HHINCOME: 84..90,
    VALUEH: 91..97 },

    person: {
      ACSYR: 2..5,
      SERIALP: 8..15,
      PERNUM: 16..19,
      PERWT: 20..29,
      RELATE: 30..31,
      SEX: 36..36,
      AGE: 37..39,
      MARST: 40..40,
      RACE: 41..41,
      HISPAN: 45..45,
      BPL: 49..51,
      YRIMMIG: 57..60,
      SPEAKENG: 61..61,
      RACESING: 62..62,
      TOTINC: 65..71,
      INCINVST: 72..77
    }
  }
end
