# remember that chrome extension content scripts run in a sandbox

Views = {}
Models = {}
Collections = {}
Templates = Handlebars.templates

# channel ids as used by skyrates
CHANNELS =
  General:  0
  Faction:  1
  Wing:     2
  Help:     10
  Roleplay: 3

MAX_RPTAG   = 16
MAX_TEXTBOX = 940

SOUNDS =
  alarm: 'Alarm'
  typewriter: 'Typewriter'
  airraid: 'Air Raid'

POPUP_DURATIONS = [4, 6, 8, 10]

ISLAND_NAMES =
  1:  "Volstoy"
  2:  "Romeo"
  3:  "Aleut"
  4:  "Juliet"
  5:  "Isla di Pisa"
  6:  "Getty"
  7:  "Fuseli"
  8:  "Tehras"
  9:  "Goldenrod"
  10: "Sharif"
  11: "Olio"
  12: "Phillipia"
  13: "Alpha 1"
  14: "Earthbreach"
  15: "Luz"
  16: "Alpha 2"
  17: "Jordan"
  18: "Shriebeck"
  19: "Leng"
  20: "Echo"
  21: "Valvia"
  22: "Lhasa"
  23: "Midgard"
  24: "Alpha 3"
  25: "Tinkspoit"
  26: "Eltsina"
  27: "Alpha 4"
  28: "Gonk"
  29: "Cidade"
  30: "Tortuga"
  31: "Alpha 5"
  32: "New Hovlund"
  33: "Steppe"
  34: "Kadath"
  35: "Arcadia"
  36: "Islo"
  37: "Grottopolis"
  38: "Uurwerk"
  39: "Alpha 6"
  40: "Alpha 7"
  41: "Alpha 8"
  42: "Alpha 9"
  43: "Alpha 10"
  44: "Alpha 11"
  45: "Alpha 12"
  46: "Alpha 13"
  47: "Alpha 14"
  48: "Alpha 15"
  49: "Alpha 16"
  50: "Alpha 17"
  51: "Fuel XIII"
  52: "Fuel XIV"
  53: "Fuel XV"
  54: "Fuel XVI"
  55: "Fuel XVII"
  56: "Fuel XVIII"
  57: "Fuel XIX"
  58: "Fuel XX"
  59: "Fuel XXI"
  60: "Fuel XXII"
  61: "Fuel XXIII"
  62: "Fuel XXIV"
  63: "Fuel XXV"
  64: "Fuel XXVI"
  65: "Fuel XXVII"
  66: "Fuel XXVIII"
  67: "Fuel XXIX"
  68: "Fuel XXX"
  69: "Fuel XXXI"
  70: "Fuel XXXII"
  71: "Fuel XXXIII"
  72: "Fuel XXXIV"
  73: "Fuel XXXV"
  74: "Fuel XXXVI"
  75: "Fuel XXXVII"
  76: "Fuel XXXVIII"
  77: "Fuel XXXIX"
  78: "Fuel XL"
  79: "Fuel XLI"
  80: "Fuel LII"
  81: "Fuel LIII"
  82: "Fuel LIV"
  83: "Fuel LV"
  84: "Fuel LVI"
  85: "Fuel LVII"
  86: "Fuel LVIII"
  87: "Fuel LIX"
  88: "Fuel LX"
  89: "Fuel LXI"

ISLAND_IMGS =
  1:  1
  2:  2
  3:  3
  4:  4
  5:  5
  6:  6
  7:  7
  8:  8
  9:  9
  10: 10
  11: 11
  12: 12
  13: 13
  14: 14
  15: 15
  16: 16
  17: 17
  18: 18
  19: 19
  20: 20
  21: 21
  22: 22
  23: 23
  24: 24
  25: 25
  26: 26
  27: 27
  28: 28
  29: 29
  30: 30
  31: 31
  32: 32
  33: 33
  34: 34
  35: 35
  36: 36
  37: 37
  38: 38
  39: 16
  40: 13
  41: 24
  42: 27
  43: 24
  44: 27
  45: 31
  46: 13
  47: 16
  48: 24
  49: 27
  50: 24
  51: 39
  52: 40
  53: 41
  54: 42
  55: 43
  56: 44
  57: 39
  58: 40
  59: 41
  60: 42
  61: 43
  62: 44
  63: 39
  64: 40
  65: 41
  66: 42
  67: 43
  68: 44
  69: 39
  70: 40
  71: 41
  72: 42
  73: 43
  74: 44
  75: 39
  76: 40
  77: 43
  78: 39
  79: 40
  80: 41
  81: 42
  82: 43
  83: 44
  84: 39
  85: 40
  86: 41
  87: 42
  88: 43
  89: 44

ITEMS =
  1:  'Wood'
  2:  'Food'
  3:  'Fish'
  4:  'Paper'
  5:  'Ore'
  6:  'Tooils'
  7:  'Oil'
  8:  'Steel'
  9:  'Grog'
  10: 'Catnip'
  11: 'Diamonds'
  12: 'Unobtanium'

MARKET =
  1: 'Scarce'
  2: 'Short Supply'
  3: 'Common'
  4: 'Well-stocked'
  5: 'Plentiful'
