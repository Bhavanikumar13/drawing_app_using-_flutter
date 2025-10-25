import 'dart:typed_data'; // For Uint8List
import 'dart:ui' as ui; // For ui.Image, ByteData
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // <-- This fixes RenderRepaintBoundary
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:math' as math; // For math functions
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class CanvasImage {
  File file;
  Offset position;
  double scale;
  bool isSelected;
  bool isBackground; // New field to distinguish background images

  CanvasImage({
    required this.file,
    required this.position,
    this.scale = 1.0,
    this.isSelected = false,
    this.isBackground = false, // Default to false
  });
}

// Emoji/Sticker class for canvas
class CanvasEmoji {
  String emoji;
  Offset position;
  double scale;
  bool isSelected;

  CanvasEmoji({
    required this.emoji,
    required this.position,
    this.scale = 1.0,
    this.isSelected = false,
  });
}

enum ToolShape {
  none,
  line,
  rectangle,
  square,
  circle,
  triangle,
  pentagon,
  hexagon,
  octagon,
  star,
  heart,
  arrow,
  diamond,
  polygon5,
  polygon6,
  polygon8,
  cloud,
  ellipse,
  semicircle,
  crescent,
}

enum LineStyle { solid, dotted, dashed }

class Stroke {
  List<Offset> points;
  Color color;
  double strokeWidth;
  bool isErasing;
  ToolShape shape;
  LineStyle lineStyle;

  Stroke({
    required this.points,
    required this.color,
    this.strokeWidth = 4.0,
    this.isErasing = false,
    this.shape = ToolShape.line,
    this.lineStyle = LineStyle.solid,
  });
}

class _DrawingScreenState extends State<DrawingScreen>
    with TickerProviderStateMixin {
  List<Stroke> strokes = [];
  List<Stroke> redoStrokes = [];
  List<CanvasImage> insertedImages = [];
  List<CanvasImage> redoImages = [];
  List<CanvasEmoji> insertedEmojis = [];
  List<CanvasEmoji> redoEmojis = [];
  List<File> savedDrawingFiles = [];

  Stroke? currentStroke;

  Color selectedColor = Colors.black;
  Color sheetColor = Colors.white;
  bool isErasing = false;
  Offset? cursorPosition;

  // Eraser properties
  double eraserSize = 20.0; // Default eraser size
  double minEraserSize = 5.0;
  double maxEraserSize = 100.0;

  ToolShape selectedShape = ToolShape.line;
  LineStyle selectedLineStyle = LineStyle.solid;
  double selectedStrokeWidth = 4.0;

  // Reset functionality
  bool showResetOptions = false;

  final List<ToolShape> _allShapes = ToolShape.values;

  final GlobalKey _canvasKey = GlobalKey();
  List<Uint8List> savedDrawings = [];
  File? insertedImage;
  Offset imagePosition = const Offset(100, 100);
  double imageScale = 1.0;
  late Offset _initialFocalPoint;
  late Offset _initialImagePos;
  double _initialScale = 1.0;
  bool isImageBeingMoved = false;

  // Animation controllers for professional UI
  late AnimationController _toolbarController;
  late AnimationController _buttonController;
  bool _isToolbarExpanded = false; // Toggle for collapsible toolbar

  @override
  void initState() {
    super.initState();
    _toolbarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _loadSavedDrawings(); // Load drawings when the screen is opened
  }

  @override
  void dispose() {
    _toolbarController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  // Available emojis for insertion
  final List<String> availableEmojis = [
    // Faces & Emotions
    '😀',
    '😁',
    '😂',
    '🤣',
    '😃',
    '😄',
    '😅',
    '😆',
    '😉',
    '😊',
    '😋',
    '😎',
    '😍',
    '😘',
    '🥰',
    '😗',
    '😙',
    '😚',
    '🙂',
    '🤗',
    '🤩',
    '🤔',
    '🤨',
    '😐',
    '😑',
    '😶',
    '🙄',
    '😏',
    '😣',
    '😥',
    '😮',
    '🤐',
    '😯',
    '😪',
    '😫',
    '🥱',
    '😴',
    '😌',
    '😛',
    '😜',
    '😝',
    '🤤',
    '😒',
    '😓',
    '😔',
    '😕',
    '🙃',
    '🫠',
    '🫡',
    '🫢',
    '🫣',
    '🫤',
    '🫥',
    '🫦',
    '🫧',
    '🫰',
    '🫱',
    '🫲',
    '🫳',
    '🫴',
    '🫵',
    '🫶',
    '🫸',
    '🫀',
    '🫁',
    '🫂',
    '🫃',
    '🫄',
    '🫅',
    '🫎',
    '🫏',
    '🫠',
    '🫦',
    '🫱',
    '🫲',
    '🫳',
    '🫴',
    '🫵',
    '🫶',
    '🫷',
    '🫸',

    // Hearts & Love
    '❤️',
    '💛',
    '💚',
    '💙',
    '💜',
    '🧡',
    '💖',
    '💗',
    '💓',
    '💞',
    '💕',
    '💟',
    '❣️',
    '💔',
    '❤️‍🔥',
    '❤️‍🩹',
    '💘',
    '💝',
    '💟',

    // Stars & Sparkles
    '⭐',
    '🌟',
    '✨',
    '💫',
    '☄️',
    '💥',
    '🔥',
    '🌪️',
    '🌈',
    '☀️',
    '🌤️',
    '⛅',
    '🌥️',
    '🌦️',
    '🌧️',
    '⛈️',
    '🌩️',
    '🌨️',
    '❄️',
    '☃️',
    '⛄',
    '💧',
    '💦',
    '☔',

    // Animals
    '🐶',
    '🐱',
    '🐭',
    '🐹',
    '🐰',
    '🦊',
    '🐻',
    '🐼',
    '🐨',
    '🐯',
    '🦁',
    '🐮',
    '🐷',
    '🐽',
    '🐸',
    '🐵',
    '🙈',
    '🙉',
    '🙊',
    '🐒',
    '🐔',
    '🐧',
    '🐦',
    '🐤',
    '🐣',
    '🐥',
    '🦆',
    '🦅',
    '🦉',
    '🦇',
    '🐺',
    '🐗',
    '🐴',
    '🦄',
    '🐝',
    '🐛',
    '🦋',
    '🐌',
    '🐞',
    '🐜',
    '🦟',
    '🦗',
    '🕷️',
    '🦂',
    '🐢',
    '🐍',
    '🦎',
    '🦖',
    '🦕',
    '🐙',
    '🦑',
    '🦐',
    '🦞',
    '🦀',
    '🐡',
    '🐠',
    '🐟',
    '🐬',
    '🐳',
    '🐋',
    '🦈',
    '🐊',
    '🐅',
    '🐆',
    '🦓',
    '🦍',
    '🦧',
    '🐘',
    '🦛',
    '🦏',
    '🐪',
    '🐫',
    '🦒',
    '🦘',
    '🐃',
    '🐂',
    '🐄',
    '🐎',
    '🐖',
    '🐏',
    '🐑',
    '🦙',
    '🐐',
    '🦌',
    '🐕',
    '🐩',
    '🦮',
    '🐕‍🦺',
    '🐈',
    '🐓',
    '🦃',
    '🦚',
    '🦜',
    '🦢',
    '🦩',
    '🕊️',
    '🐇',
    '🦝',
    '🦨',
    '🦡',
    '🦦',
    '🦥',
    '🐁',
    '🐿️',
    '🦔',

    // Food & Drinks
    '🍏',
    '🍎',
    '🍐',
    '🍊',
    '🍋',
    '🍌',
    '🍉',
    '🍇',
    '🍓',
    '🍈',
    '🍒',
    '🍑',
    '🥭',
    '🍍',
    '🥥',
    '🥝',
    '🍅',
    '🍆',
    '🥑',
    '🥦',
    '🥬',
    '🥒',
    '🌶️',
    '🫑',
    '🌽',
    '🥕',
    '🫒',
    '🧄',
    '🧅',
    '🥔',
    '🍠',
    '🥐',
    '🥯',
    '🍞',
    '🥖',
    '🥨',
    '🧀',
    '🥚',
    '🍳',
    '🧈',
    '🥞',
    '🧇',
    '🥓',
    '🥩',
    '🍗',
    '🍖',
    '🦴',
    '🌭',
    '🍔',
    '🍟',
    '🍕',
    '🥪',
    '🥙',
    '🧆',
    '🌮',
    '🌯',
    '🫔',
    '🥗',
    '🥘',
    '🫕',
    '🥫',
    '🍝',
    '🍜',
    '🍲',
    '🍛',
    '🍣',
    '🍱',
    '🥟',
    '🦪',
    '🍤',
    '🍙',
    '🍚',
    '🍘',
    '🍥',
    '🥠',
    '🥮',
    '🍢',
    '🍡',
    '🍧',
    '🍨',
    '🍦',
    '🥧',
    '🧁',
    '🍰',
    '🎂',
    '🍮',
    '🍭',
    '🍬',
    '🍫',
    '🍿',
    '🍩',
    '🍪',
    '🌰',
    '🥜',
    '🍯',
    '🥛',
    '🍼',
    '☕',
    '🍵',
    '🧃',
    '🥤',
    '🧋',
    '🍶',
    '🍺',
    '🍻',
    '🥂',
    '🍷',
    '🥃',
    '🍸',
    '🍹',
    '🧉',
    '🍾',
    '🧊',

    // Activities & Sports
    '⚽',
    '🏀',
    '🏈',
    '⚾',
    '🥎',
    '🎾',
    '🏐',
    '🏉',
    '🥏',
    '🎱',
    '🪀',
    '🏓',
    '🏸',
    '🏒',
    '🏑',
    '🥍',
    '🏏',
    '🪃',
    '🥅',
    '⛳',
    '🪁',
    '🏹',
    '🎣',
    '🤿',
    '🥊',
    '🥋',
    '🎽',
    '🛹',
    '🛼',
    '⛸️',
    '🥌',
    '🎿',
    '⛷️',
    '🏂',
    '🪂',
    '🏋️',
    '🤼',
    '🤸',
    '⛹️',
    '🤺',
    '🤾',
    '🏌️',
    '🏇',
    '🧘',
    '🏄',
    '🏊',
    '🤽',
    '🚣',
    '🧗',
    '🚵',
    '🚴',
    '🏆',
    '🥇',
    '🥈',
    '🥉',
    '🏅',
    '🎖️',
    '🏵️',
    '🎗️',
    '🎫',
    '🎟️',
    '🎪',
    '🤹',
    '🎭',
    '🩰',
    '🎨',
    '🎬',
    '🎤',
    '🎧',
    '🎼',
    '🎹',
    '🥁',
    '🎷',
    '🎺',
    '🎸',
    '🪕',
    '🎻',
    '🎲',
    '♟️',
    '🎯',
    '🎳',
    '🎮',
    '🎰',

    // Transportation
    '🚗',
    '🚕',
    '🚙',
    '🚌',
    '🚎',
    '🏎️',
    '🚓',
    '🚑',
    '🚒',
    '🚐',
    '🚚',
    '🚛',
    '🚜',
    '🦯',
    '🦽',
    '🦼',
    '🛴',
    '🚲',
    '🛵',
    '🏍️',
    '🛺',
    '🚨',
    '🚔',
    '🚍',
    '🚘',
    '🚖',
    '🚡',
    '🚠',
    '🚟',
    '🚃',
    '🚋',
    '🚞',
    '🚝',
    '🚄',
    '🚅',
    '🚈',
    '🚂',
    '🚆',
    '🚇',
    '🚊',
    '🚉',
    '✈️',
    '🛫',
    '🛬',
    '🛩️',
    '💺',
    '🛰️',
    '🚀',
    '🛸',
    '🚁',
    '🛶',
    '⛵',
    '🚤',
    '🛥️',
    '🛳️',
    '⛴️',
    '🚢',

    // Objects & Items
    '⌚',
    '📱',
    '📲',
    '💻',
    '⌨️',
    '🖥️',
    '🖨️',
    '🖱️',
    '🖲️',
    '🕹️',
    '🗜️',
    '💽',
    '💾',
    '💿',
    '📀',
    '📼',
    '📷',
    '📸',
    '📹',
    '🎥',
    '📽️',
    '🎞️',
    '📞',
    '☎️',
    '📟',
    '📠',
    '📺',
    '📻',
    '🎙️',
    '🎚️',
    '🎛️',
    '🧭',
    '⏱️',
    '⏲️',
    '⏰',
    '🕰️',
    '⌛',
    '⏳',
    '📡',
    '🔋',
    '🔌',
    '💡',
    '🔦',
    '🕯️',
    '🪔',
    '🧯',
    '🛢️',
    '💸',
    '💵',
    '💴',
    '💶',
    '💷',
    '💰',
    '💳',
    '💎',
    '⚖️',
    '🧰',
    '🔧',
    '🔨',
    '⚒️',
    '🛠️',
    '⛏️',
    '🔩',
    '⚙️',
    '🧱',
    '⛓️',
    '🧲',
    '🔫',
    '💣',
    '🧨',
    '🪓',
    '🔪',
    '🗡️',
    '⚔️',
    '🛡️',
    '🚬',
    '⚰️',
    '🪦',
    '⚱️',
    '🏺',
    '🔮',
    '📿',
    '💈',
    '⚗️',
    '🔭',
    '🔬',
    '🕳️',
    '🩹',
    '🩺',
    '💊',
    '💉',
    '🩸',
    '🧬',
    '🦠',
    '🧫',
    '🧪',
    '🌡️',
    '🧹',
    '🪠',
    '🧺',
    '🧻',
    '🚽',
    '🪣',
    '🧼',
    '🪥',
    '🧽',
    '🧯',
    '🛒',
    '🚬',

    // Symbols & Signs
    '🏧',
    '🚮',
    '🚰',
    '♿',
    '🚹',
    '🚺',
    '🚻',
    '🚼',
    '🚾',
    '🛂',
    '🛃',
    '🛄',
    '🛅',
    '⚠️',
    '🚸',
    '⛔',
    '🚫',
    '🚳',
    '🚭',
    '🚯',
    '🚱',
    '🚷',
    '📵',
    '🔞',
    '☢️',
    '☣️',
    '⬆️',
    '↗️',
    '➡️',
    '↘️',
    '⬇️',
    '↙️',
    '⬅️',
    '↖️',
    '↕️',
    '↔️',
    '↩️',
    '↪️',
    '⤴️',
    '⤵️',
    '🔃',
    '🔄',
    '🔙',
    '🔚',
    '🔛',
    '🔜',
    '🔝',
    '🛐',
    '⚛️',
    '🕉️',
    '✡️',
    '☸️',
    '☯️',
    '✝️',
    '☦️',
    '☪️',
    '☮️',
    '🕎',
    '🔯',
    '♈',
    '♉',
    '♊',
    '♋',
    '♌',
    '♍',
    '♎',
    '♏',
    '♐',
    '♑',
    '♒',
    '♓',
    '⛎',
    '🔀',
    '🔁',
    '🔂',
    '▶️',
    '⏩',
    '⏭️',
    '⏯️',
    '◀️',
    '⏪',
    '⏮️',
    '🔼',
    '⏫',
    '🔽',
    '⏬',
    '⏸️',
    '⏹️',
    '⏺️',
    '⏏️',
    '🎦',
    '🔅',
    '🔆',
    '📶',
    '📳',
    '📴',
    '♀️',
    '♂️',
    '⚧️',
    '✖️',
    '➕',
    '➖',
    '➗',
    '♾️',
    '‼️',
    '⁉️',
    '❓',
    '❔',
    '❕',
    '❗',
    '〰️',
    '💱',
    '💲',
    '⚕️',
    '♻️',
    '⚜️',
    '🔱',
    '📛',
    '🔰',
    '⭕',
    '✅',
    '☑️',
    '✔️',
    '❌',
    '❎',
    '➰',
    '➿',
    '〽️',
    '✳️',
    '✴️',
    '❇️',
    '©️',
    '®️',
    '™️',
    '🔠',
    '🔡',
    '🔢',
    '🔣',
    '🔤',
    '🅰️',
    '🆎',
    '🅱️',
    '🆑',
    '🆒',
    '🆓',
    'ℹ️',
    '🆔',
    'Ⓜ️',
    '🆕',
    '🆖',
    '🅾️',
    '🆗',
    '🅿️',
    '🆘',
    '🆙',
    '🆚',
    '🈁',
    '🈂️',
    '🈷️',
    '🈶',
    '🈯',
    '🉐',
    '🈹',
    '🈚',
    '🈲',
    '🉑',
    '🈸',
    '🈴',
    '🈳',
    '㊗️',
    '㊙️',
    '🈺',
    '🈵',
    '🔴',
    '🟠',
    '🟡',
    '🟢',
    '🔵',
    '🟣',
    '🟤',
    '⚫',
    '⚪',
    '🟥',
    '🟧',
    '🟨',
    '🟩',
    '🟦',
    '🟪',
    '🟫',
    '⬛',
    '⬜',
    '◼️',
    '◻️',
    '◾',
    '◽',
    '▪️',
    '▫️',
    '🔶',
    '🔷',
    '🔸',
    '🔹',
    '🔺',
    '🔻',
    '💠',
    '🔘',
    '🔳',
    '🔲',

    // Flags
    '🏁',
    '🚩',
    '🎌',
    '🏴',
    '🏳️',
    '🏳️‍🌈',
    '🏳️‍⚧️',
    '🏴‍☠️',

    // Special Kids Emojis
    '🧸',
    '🪂',
    '🪐',
    '🪠',
    '🪣',
    '🪤',
    '🪣',
    '🪥',
    '🪦',
    '🪧',
    '🪨',
    '🪩',
    '🪪',
    '🪫',
    '🪬',
    '🪭',
    '🪮',
    '🪯',
    '🪰',
    '🪱',
    '🪲',
    '🪳',
    '🪴',
    '🪵',
    '🪶',
    '🫀',
    '🫁',
    '🫂',
    '🫃',
    '🫄',
    '🫅',
    '🫎',
    '🫏',
    '🫐',
    '🫑',
    '🫒',
    '🫓',
    '🫔',
  ];

  void startStroke(Offset point) {
    setState(() {
      currentStroke = Stroke(
        points: [point],
        color: isErasing ? sheetColor : selectedColor,
        strokeWidth: isErasing ? eraserSize : selectedStrokeWidth,
        isErasing: isErasing,
        shape: isErasing ? ToolShape.line : selectedShape,
        lineStyle: selectedLineStyle,
      );
      cursorPosition = point;
      redoStrokes.clear();
    });
  }

  // Reset all shapes to default
  void resetShapes() {
    setState(() {
      selectedShape = ToolShape.line;
      selectedLineStyle = LineStyle.solid;
      selectedStrokeWidth = 4.0;
      showResetOptions = false;
    });
  }

  // Reset only stroke width
  void resetStrokeWidth() {
    setState(() {
      selectedStrokeWidth = 4.0;
      showResetOptions = false;
    });
  }

  // Reset only line style
  void resetLineStyle() {
    setState(() {
      selectedLineStyle = LineStyle.solid;
      showResetOptions = false;
    });
  }

  // Reset only shape
  void resetShape() {
    setState(() {
      selectedShape = ToolShape.line;
      showResetOptions = false;
    });
  }

  void addPoint(Offset point) {
    setState(() {
      currentStroke?.points.add(point);
      cursorPosition = point;
    });
  }

  void endStroke() {
    setState(() {
      if (currentStroke != null && currentStroke!.points.isNotEmpty) {
        strokes.add(currentStroke!);
      }
      currentStroke = null;
      cursorPosition = null;
    });
  }

  void undo() {
    if (strokes.isNotEmpty) {
      setState(() {
        redoStrokes.add(strokes.removeLast());
      });
    } else if (insertedEmojis.isNotEmpty) {
      setState(() {
        redoEmojis.add(insertedEmojis.removeLast());
      });
    } else if (insertedImages.isNotEmpty) {
      setState(() {
        redoImages.add(insertedImages.removeLast());
      });
    }
  }

  void redo() {
    if (redoStrokes.isNotEmpty) {
      setState(() {
        strokes.add(redoStrokes.removeLast());
      });
    } else if (redoEmojis.isNotEmpty) {
      setState(() {
        insertedEmojis.add(redoEmojis.removeLast());
      });
    } else if (redoImages.isNotEmpty) {
      setState(() {
        insertedImages.add(redoImages.removeLast());
      });
    }
  }

  void clearCanvas() {
    setState(() {
      strokes.clear();
      redoStrokes.clear();
      insertedImages.clear();
      insertedEmojis.clear();
      currentStroke = null;
      cursorPosition = null;
    });
  }

  void changeColor(Color color) {
    setState(() {
      selectedColor = color;
      isErasing = false;
    });
  }

  void changeSheetColor(Color color) {
    setState(() {
      sheetColor = color;
    });
  }

  // Save Drawing including background color
  Future<void> _saveDrawing() async {
    try {
      RenderRepaintBoundary boundary =
          _canvasKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // Convert to PNG bytes
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return;
      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save file in app documents directory
      final dir = await getApplicationDocumentsDirectory();
      String fileName = "drawing_${DateTime.now().millisecondsSinceEpoch}.png";
      File file = File("${dir.path}/$fileName");
      await file.writeAsBytes(pngBytes);

      setState(() {
        savedDrawings.add(pngBytes);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.emoji_emotions, color: Colors.yellow),
              SizedBox(width: 10),
              Text("Drawing Saved! 🎨"),
            ],
          ),
          backgroundColor: Colors.purpleAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error saving drawing: $e");
    }
  }

  // View Saved Drawings (improved for kids)
  void _viewDrawings() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.pink[50],
          appBar: AppBar(
            title: const Text("My Gallery 🎨"),
            backgroundColor: Colors.deepPurple,
          ),
          body: savedDrawings.isEmpty
              ? const Center(
                  child: Text(
                    "No drawings yet!\nLet's create some art 🖌️",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.deepPurple),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
                    itemCount: savedDrawings.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          // Full-screen view with delete
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                backgroundColor: Colors.black,
                                appBar: AppBar(
                                  backgroundColor: Colors.deepPurple,
                                  title: const Text("Your Masterpiece 🌟"),
                                  actions: [
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text(
                                              "Delete Drawing? 🗑️",
                                            ),
                                            content: const Text(
                                              "Are you sure you want to delete this permanently?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: const Text("Cancel"),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                              TextButton(
                                                child: const Text("Delete"),
                                                onPressed: () async {
                                                  if (!context.mounted) return;
                                                  final navigator =
                                                      Navigator.of(context);
                                                  final messenger =
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      );

                                                  try {
                                                    // Get app documents directory
                                                    final dir =
                                                        await getApplicationDocumentsDirectory();
                                                    final files = dir
                                                        .listSync()
                                                        .whereType<File>()
                                                        .toList();

                                                    // Match the file by content
                                                    final fileToDelete = files
                                                        .firstWhere(
                                                          (f) =>
                                                              f
                                                                  .readAsBytesSync()
                                                                  .toString() ==
                                                              savedDrawings[index]
                                                                  .toString(),
                                                          orElse: () =>
                                                              File(''),
                                                        );

                                                    if (fileToDelete
                                                        .existsSync()) {
                                                      await fileToDelete
                                                          .delete();
                                                    }

                                                    setState(() {
                                                      savedDrawings.removeAt(
                                                        index,
                                                      );
                                                    });

                                                    navigator
                                                        .pop(); // Close dialog
                                                    navigator
                                                        .pop(); // Close full-screen view

                                                    messenger.showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Deleted successfully 🗑️',
                                                        ),
                                                        backgroundColor:
                                                            Colors.redAccent,
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    debugPrint(
                                                      "Error deleting file: $e",
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                body: Center(
                                  child: InteractiveViewer(
                                    child: Image.memory(savedDrawings[index]),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(3, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              savedDrawings[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _loadSavedDrawings() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync().whereType<File>().toList();

    List<Uint8List> drawings = [];
    for (var file in files) {
      if (file.path.endsWith(".png") && file.path.contains("drawing_")) {
        drawings.add(await file.readAsBytes());
      }
    }

    setState(() {
      savedDrawings = drawings;
    });
  }

  Future<void> _insertImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        insertedImages.add(
          CanvasImage(
            file: File(pickedFile.path),
            position: const Offset(100, 100),
            scale: 1.0,
          ),
        );
      });
    }
  }

  Future<void> _insertBackgroundImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        // Remove any existing background image
        insertedImages.removeWhere((image) => image.isBackground);

        // Add the new background image
        insertedImages.add(
          CanvasImage(
            file: File(pickedFile.path),
            position: Offset.zero, // Start at top-left
            scale: 1.0,
            isBackground: true, // Mark as background
          ),
        );
      });
    }
  }

  // Show emoji picker dialog
  void _showEmojiPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '😀 Pick an Emoji',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: availableEmojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      insertedEmojis.add(
                        CanvasEmoji(
                          emoji: availableEmojis[index],
                          position: Offset(
                            MediaQuery.of(context).size.width / 2 - 50,
                            MediaQuery.of(context).size.height / 2 - 50,
                          ),
                          scale: 1.5,
                        ),
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        availableEmojis[index],
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sheetColor,
      appBar: AppBar(
        title: const Text('Drawing Board'),
        backgroundColor: Colors.deepPurple,
        elevation: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _topBarButton(
            'BG Image',
            Colors.green,
            onTap: _insertBackgroundImage,
          ),
          _topBarButton('Save', Colors.orangeAccent, onTap: _saveDrawing),
          _topBarButton(
            'Gallery',
            Colors.lightBlueAccent,
            onTap: _viewDrawings,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              final RenderBox renderBox =
                  _canvasKey.currentContext!.findRenderObject() as RenderBox;
              final localPos = renderBox.globalToLocal(details.globalPosition);

              // Only check for non-background images for moving
              bool foundNonBackgroundImage = false;
              for (int i = 0; i < insertedImages.length; i++) {
                if (insertedImages[i].isBackground)
                  continue; // Skip background images

                final imageRect = Rect.fromLTWH(
                  insertedImages[i].position.dx,
                  insertedImages[i].position.dy,
                  200 * insertedImages[i].scale,
                  200 * insertedImages[i].scale,
                );
                if (imageRect.contains(localPos)) {
                  setState(() => isImageBeingMoved = true);
                  foundNonBackgroundImage = true;
                  break;
                }
              }

              if (!foundNonBackgroundImage) {
                startStroke(localPos);
              }
            },
            onPanUpdate: (details) {
              final RenderBox renderBox =
                  _canvasKey.currentContext!.findRenderObject() as RenderBox;
              final localPos = renderBox.globalToLocal(details.globalPosition);
              if (isImageBeingMoved) return;
              addPoint(localPos);
            },
            onPanEnd: (details) {
              if (isImageBeingMoved) {
                setState(() => isImageBeingMoved = false);
                return;
              }
              endStroke();
            },
            child: RepaintBoundary(
              key: _canvasKey,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: _DrawingPainter(
                      strokes: strokes,
                      currentStroke: currentStroke,
                      backgroundColor: sheetColor,
                    ),
                  ),

                  // Render background images first (behind drawings)
                  for (int i = 0; i < insertedImages.length; i++)
                    if (insertedImages[i].isBackground)
                      Stack(
                        children: [
                          Positioned.fill(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: Image.file(
                                insertedImages[i].file,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Delete button for background images
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  insertedImages.removeAt(i);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                  // Render regular images (in front of drawings)
                  for (int i = 0; i < insertedImages.length; i++)
                    if (!insertedImages[i].isBackground)
                      Positioned(
                        left: insertedImages[i].position.dx,
                        top: insertedImages[i].position.dy,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              // Toggle selection for this image
                              insertedImages[i].isSelected =
                                  !insertedImages[i].isSelected;

                              // Deselect all other images
                              for (int j = 0; j < insertedImages.length; j++) {
                                if (j != i)
                                  insertedImages[j].isSelected = false;
                              }
                            });
                          },
                          onScaleStart: (details) {
                            final RenderBox renderBox =
                                _canvasKey.currentContext!.findRenderObject()
                                    as RenderBox;
                            _initialFocalPoint = renderBox.globalToLocal(
                              details.focalPoint,
                            );
                            _initialImagePos = insertedImages[i].position;
                            _initialScale =
                                insertedImages[i].scale; // store current scale
                          },
                          onScaleUpdate: (details) {
                            final RenderBox renderBox =
                                _canvasKey.currentContext!.findRenderObject()
                                    as RenderBox;
                            final localFocal = renderBox.globalToLocal(
                              details.focalPoint,
                            );

                            setState(() {
                              insertedImages[i].scale =
                                  (_initialScale * details.scale).clamp(
                                    0.2,
                                    5.0,
                                  );
                              final focalDelta =
                                  localFocal - _initialFocalPoint;
                              insertedImages[i].position =
                                  _initialImagePos + focalDelta;
                            });
                          },
                          child: Stack(
                            children: [
                              Transform.scale(
                                scale: insertedImages[i].scale,
                                alignment: Alignment.topLeft,
                                child: Image.file(
                                  insertedImages[i].file,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              if (insertedImages[i].isSelected) ...[
                                // Increase size button
                                Positioned(
                                  bottom: 10,
                                  right: 40,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        insertedImages[i].scale =
                                            (insertedImages[i].scale + 0.2)
                                                .clamp(0.2, 5.0);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                // Decrease size button
                                Positioned(
                                  bottom: 10,
                                  right: 5,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        insertedImages[i].scale =
                                            (insertedImages[i].scale - 0.2)
                                                .clamp(0.2, 5.0);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                // Delete button
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        redoImages.add(
                                          insertedImages.removeAt(i),
                                        );
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),

          // Render emojis with zoom/drag
          for (int i = 0; i < insertedEmojis.length; i++)
            Positioned(
              left: insertedEmojis[i].position.dx,
              top: insertedEmojis[i].position.dy,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    insertedEmojis[i].isSelected =
                        !insertedEmojis[i].isSelected;
                    for (int j = 0; j < insertedEmojis.length; j++) {
                      if (j != i) {
                        insertedEmojis[j].isSelected = false;
                      }
                    }
                  });
                },
                onScaleStart: (details) {
                  final RenderBox renderBox =
                      _canvasKey.currentContext!.findRenderObject()
                          as RenderBox;
                  _initialFocalPoint = renderBox.globalToLocal(
                    details.focalPoint,
                  );
                  _initialImagePos = insertedEmojis[i].position;
                  _initialScale = insertedEmojis[i].scale;
                },
                onScaleUpdate: (details) {
                  final RenderBox renderBox =
                      _canvasKey.currentContext!.findRenderObject()
                          as RenderBox;
                  final localFocal = renderBox.globalToLocal(
                    details.focalPoint,
                  );
                  setState(() {
                    insertedEmojis[i].scale = (_initialScale * details.scale)
                        .clamp(0.5, 8.0);
                    final focalDelta = localFocal - _initialFocalPoint;
                    insertedEmojis[i].position = _initialImagePos + focalDelta;
                  });
                },
                child: Stack(
                  children: [
                    Transform.scale(
                      scale: insertedEmojis[i].scale,
                      child: Container(
                        decoration: BoxDecoration(
                          border: insertedEmojis[i].isSelected
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          insertedEmojis[i].emoji,
                          style: const TextStyle(fontSize: 50),
                        ),
                      ),
                    ),
                    if (insertedEmojis[i].isSelected)
                    // Add resize buttons for emojis
                    ...[
                      // Increase size button
                      Positioned(
                        bottom: -10,
                        right: 30,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              insertedEmojis[i].scale =
                                  (insertedEmojis[i].scale + 0.2).clamp(
                                    0.5,
                                    8.0,
                                  );
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      // Decrease size button
                      Positioned(
                        bottom: -10,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              insertedEmojis[i].scale =
                                  (insertedEmojis[i].scale - 0.2).clamp(
                                    0.5,
                                    8.0,
                                  );
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.remove,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      // Delete button (moved)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              redoEmojis.add(insertedEmojis.removeAt(i));
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          if (cursorPosition != null)
            Positioned(
              left: cursorPosition!.dx - (isErasing ? eraserSize / 2 : 15),
              top: cursorPosition!.dy - (isErasing ? eraserSize / 2 : 15),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isErasing
                    ? Container(
                        width: eraserSize,
                        height: eraserSize,
                        decoration: BoxDecoration(
                          color: sheetColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.redAccent, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 6,
                              offset: const Offset(3, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.auto_fix_high,
                            color: Colors.redAccent,
                            size: eraserSize * 0.6 > 30 ? 30 : eraserSize * 0.6,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.brush,
                        key: ValueKey(isErasing),
                        color: selectedColor,
                        size: 24,
                      ),
              ),
            ),
          // Compact Side Toolbar - More Drawing Space!
          Positioned(
            right: 12,
            top: 120,
            bottom: 120,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _compactToolButton(
                    icon: Icons.color_lens,
                    color: selectedColor,
                    tooltip: 'Color',
                    onPressed: () {
                      setState(() => isErasing = false);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Row(
                            children: [
                              Icon(Icons.palette, color: selectedColor),
                              const SizedBox(width: 8),
                              const Text(
                                'Pick a Color',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          content: SingleChildScrollView(
                            child: BlockPicker(
                              pickerColor: selectedColor,
                              onColorChanged: changeColor,
                              availableColors: [
                                // Primary colors
                                Colors.red,
                                Colors.pink,
                                Colors.purple,
                                Colors.deepPurple,
                                Colors.indigo,
                                Colors.blue,
                                Colors.lightBlue,
                                Colors.cyan,
                                Colors.teal,
                                Colors.green,
                                Colors.lightGreen,
                                Colors.lime,
                                Colors.yellow,
                                Colors.amber,
                                Colors.orange,
                                Colors.deepOrange,
                                Colors.brown,
                                Colors.grey,
                                Colors.blueGrey,
                                Colors.black,
                                Colors.white,
                                // Additional vibrant colors for kids
                                Colors.redAccent,
                                Colors.pinkAccent,
                                Colors.purpleAccent,
                                Colors.deepPurpleAccent,
                                Colors.indigoAccent,
                                Colors.blueAccent,
                                Colors.lightBlueAccent,
                                Colors.cyanAccent,
                                Colors.tealAccent,
                                Colors.greenAccent,
                                Colors.lightGreenAccent,
                                Colors.limeAccent,
                                Colors.yellowAccent,
                                Colors.amberAccent,
                                Colors.orangeAccent,
                                Colors.deepOrangeAccent,
                                // Pastel colors
                                const Color(0xFFff9a9e), // Pink
                                const Color(0xFFfad0c4), // Peach
                                const Color(0xFFa1c4fd), // Light blue
                                const Color(0xFFc2e9fb), // Sky blue
                                const Color(0xFFd4fc79), // Light green
                                const Color(0xFF96e6a1), // Mint
                                const Color(0xFF84fab0), // Aqua
                                const Color(0xFFa6c0fe), // Periwinkle
                                const Color(0xFFf6d365), // Golden yellow
                                const Color(0xFFfda085), // Salmon
                                const Color(0xFFfccb90), // Light orange
                                const Color(0xFFe0c3fc), // Lavender
                                const Color(0xFFffecd2), // Cream
                                const Color(0xFFfcb69f), // Coral
                                const Color(0xFFff8a80), // Light red
                                const Color(0xFF82b1ff), // Bright blue
                                const Color(0xFFb388ff), // Violet
                                const Color(0xFF1de9b6), // Turquoise
                                const Color(0xFFffcc00), // Bright yellow
                                const Color(0xFFff6d00), // Bright orange
                                const Color(0xFFff1744), // Bright red
                                const Color(0xFF6200ea), // Deep purple
                                const Color(0xFF00b0ff), // Electric blue
                                const Color(0xFF00c853), // Bright green
                                const Color(0xFFff4081), // Hot pink
                                const Color(0xFF7c4dff), // Deep violet
                                const Color(0xFF304ffe), // Royal blue
                                const Color(0xFF00bfa5), // Dark teal
                                const Color(0xFFffd600), // Bright gold
                                const Color(0xFFff6e40), // Deep orange
                                const Color(0xFFff5252), // Red orange
                                const Color(0xFF448aff), // Bright blue
                                const Color(0xFF18ffff), // Bright cyan
                                const Color(0xFF69f0ae), // Bright mint
                                const Color(0xFFeeff41), // Lime yellow
                                const Color(0xFFffab00), // Amber
                                const Color(0xFFff4081), // Pink
                                const Color(0xFFe040fb), // Purple
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Done'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _compactToolButton(
                    icon: Icons.circle,
                    color: Colors.white,
                    iconColor: Colors.redAccent,
                    tooltip: 'Eraser',
                    onPressed: () {
                      // Show eraser options dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Row(
                            children: [
                              Icon(
                                Icons.auto_fix_high,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Eraser Settings',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Eraser Size',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Slider(
                                value: eraserSize,
                                min: minEraserSize,
                                max: maxEraserSize,
                                divisions: (maxEraserSize - minEraserSize)
                                    .toInt(),
                                activeColor: Colors.redAccent,
                                label: eraserSize.round().toString(),
                                onChanged: (value) {
                                  setState(() {
                                    eraserSize = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Size: ${eraserSize.round()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Professional eraser preview
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: sheetColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.redAccent,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.auto_fix_high,
                                    color: Colors.redAccent,
                                    size: eraserSize * 0.6 > 30
                                        ? 30
                                        : eraserSize * 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Use Eraser'),
                              onPressed: () {
                                setState(() => isErasing = true);
                                Navigator.pop(context);
                              },
                            ),
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _compactToolButton(
                    icon: Icons.layers,
                    color: sheetColor,
                    tooltip: 'Sheet Color',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Row(
                            children: [
                              Icon(Icons.layers, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Sheet Color',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          content: SingleChildScrollView(
                            child: BlockPicker(
                              pickerColor: sheetColor,
                              onColorChanged: changeSheetColor,
                              availableColors: [
                                // Primary colors
                                Colors.red,
                                Colors.pink,
                                Colors.purple,
                                Colors.deepPurple,
                                Colors.indigo,
                                Colors.blue,
                                Colors.lightBlue,
                                Colors.cyan,
                                Colors.teal,
                                Colors.green,
                                Colors.lightGreen,
                                Colors.lime,
                                Colors.yellow,
                                Colors.amber,
                                Colors.orange,
                                Colors.deepOrange,
                                Colors.brown,
                                Colors.grey,
                                Colors.blueGrey,
                                Colors.black,
                                Colors.white,
                                // Additional vibrant colors for kids
                                Colors.redAccent,
                                Colors.pinkAccent,
                                Colors.purpleAccent,
                                Colors.deepPurpleAccent,
                                Colors.indigoAccent,
                                Colors.blueAccent,
                                Colors.lightBlueAccent,
                                Colors.cyanAccent,
                                Colors.tealAccent,
                                Colors.greenAccent,
                                Colors.lightGreenAccent,
                                Colors.limeAccent,
                                Colors.yellowAccent,
                                Colors.amberAccent,
                                Colors.orangeAccent,
                                Colors.deepOrangeAccent,
                                // Pastel colors
                                const Color(0xFFff9a9e), // Pink
                                const Color(0xFFfad0c4), // Peach
                                const Color(0xFFa1c4fd), // Light blue
                                const Color(0xFFc2e9fb), // Sky blue
                                const Color(0xFFd4fc79), // Light green
                                const Color(0xFF96e6a1), // Mint
                                const Color(0xFF84fab0), // Aqua
                                const Color(0xFFa6c0fe), // Periwinkle
                                const Color(0xFFf6d365), // Golden yellow
                                const Color(0xFFfda085), // Salmon
                                const Color(0xFFfccb90), // Light orange
                                const Color(0xFFe0c3fc), // Lavender
                                const Color(0xFFffecd2), // Cream
                                const Color(0xFFfcb69f), // Coral
                                const Color(0xFFff8a80), // Light red
                                const Color(0xFF82b1ff), // Bright blue
                                const Color(0xFFb388ff), // Violet
                                const Color(0xFF1de9b6), // Turquoise
                                const Color(0xFFffcc00), // Bright yellow
                                const Color(0xFFff6d00), // Bright orange
                                const Color(0xFFff1744), // Bright red
                                const Color(0xFF6200ea), // Deep purple
                                const Color(0xFF00b0ff), // Electric blue
                                const Color(0xFF00c853), // Bright green
                                const Color(0xFFff4081), // Hot pink
                                const Color(0xFF7c4dff), // Deep violet
                                const Color(0xFF304ffe), // Royal blue
                                const Color(0xFF00bfa5), // Dark teal
                                const Color(0xFFffd600), // Bright gold
                                const Color(0xFFff6e40), // Deep orange
                                const Color(0xFFff5252), // Red orange
                                const Color(0xFF448aff), // Bright blue
                                const Color(0xFF18ffff), // Bright cyan
                                const Color(0xFF69f0ae), // Bright mint
                                const Color(0xFFeeff41), // Lime yellow
                                const Color(0xFFffab00), // Amber
                                const Color(0xFFff4081), // Pink
                                const Color(0xFFe040fb), // Purple
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Done'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _compactToolButton(
                    icon: Icons.auto_awesome,
                    color: Colors.blueAccent,
                    tooltip: 'Shapes & Tools',
                    onPressed: () {
                      showModalBottomSheet(
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        context: context,
                        builder: (context) => StatefulBuilder(
                          builder: (BuildContext context, StateSetter setState) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade50,
                                    Colors.purple.shade50,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            color: Colors.purple.shade700,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Drawing Tools',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                              color: Colors.purple.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.purple.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.category,
                                                      color:
                                                          Colors.blue.shade700,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Shapes',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .blue
                                                            .shade900,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    showResetOptions
                                                        ? Icons.expand_less
                                                        : Icons.expand_more,
                                                    color: Colors.blue.shade700,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      showResetOptions =
                                                          !showResetOptions;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            GridView.count(
                                              crossAxisCount: 4,
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              mainAxisSpacing: 8,
                                              crossAxisSpacing: 8,
                                              children: _allShapes
                                                  .where(
                                                    (e) => e != ToolShape.none,
                                                  )
                                                  .map((shape) {
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            selectedShape ==
                                                                shape
                                                            ? LinearGradient(
                                                                colors: [
                                                                  Colors
                                                                      .blue
                                                                      .shade300,
                                                                  Colors
                                                                      .purple
                                                                      .shade300,
                                                                ],
                                                              )
                                                            : null,
                                                        color:
                                                            selectedShape !=
                                                                shape
                                                            ? Colors
                                                                  .grey
                                                                  .shade100
                                                            : null,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              selectedShape ==
                                                                  shape
                                                              ? Colors
                                                                    .blue
                                                                    .shade700
                                                              : Colors
                                                                    .grey
                                                                    .shade300,
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: InkWell(
                                                        onTap: () => setState(
                                                          () => selectedShape =
                                                              shape,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            _shapeIcon(shape),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              shape.name,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                fontSize: 9,
                                                                fontWeight:
                                                                    selectedShape ==
                                                                        shape
                                                                    ? FontWeight
                                                                          .bold
                                                                    : FontWeight
                                                                          .normal,
                                                                color:
                                                                    selectedShape ==
                                                                        shape
                                                                    ? Colors
                                                                          .white
                                                                    : Colors
                                                                          .black87,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  })
                                                  .toList(),
                                            ),
                                            if (showResetOptions) ...[
                                              const SizedBox(height: 12),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    ElevatedButton(
                                                      onPressed: resetShape,
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors
                                                            .blue
                                                            .shade300,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'Reset Shape',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: resetShapes,
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red.shade300,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'Reset All',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.purple.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.line_style,
                                                  color: Colors.green.shade700,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Line Styles',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.green.shade900,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 10,
                                              children: LineStyle.values.map((
                                                style,
                                              ) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        selectedLineStyle ==
                                                            style
                                                        ? LinearGradient(
                                                            colors: [
                                                              Colors
                                                                  .green
                                                                  .shade300,
                                                              Colors
                                                                  .teal
                                                                  .shade300,
                                                            ],
                                                          )
                                                        : null,
                                                    color:
                                                        selectedLineStyle !=
                                                            style
                                                        ? Colors.grey.shade100
                                                        : null,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          selectedLineStyle ==
                                                              style
                                                          ? Colors
                                                                .green
                                                                .shade700
                                                          : Colors
                                                                .grey
                                                                .shade300,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: InkWell(
                                                    onTap: () {
                                                      setState(
                                                        () =>
                                                            selectedLineStyle =
                                                                style,
                                                      );
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 10,
                                                          ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          _lineIcon(style),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            style.name,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  selectedLineStyle ==
                                                                      style
                                                                  ? FontWeight
                                                                        .bold
                                                                  : FontWeight
                                                                        .normal,
                                                              color:
                                                                  selectedLineStyle ==
                                                                      style
                                                                  ? Colors.white
                                                                  : Colors
                                                                        .black87,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                            const SizedBox(height: 8),
                                            ElevatedButton(
                                              onPressed: resetLineStyle,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.green.shade300,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: const Text(
                                                'Reset Line Style',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.purple.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.line_weight,
                                                  color: Colors.orange.shade700,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Width:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.orange.shade900,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Slider(
                                              value: selectedStrokeWidth,
                                              min: 1,
                                              max: 20,
                                              divisions: 19,
                                              activeColor:
                                                  Colors.orange.shade600,
                                              label: selectedStrokeWidth
                                                  .round()
                                                  .toString(),
                                              onChanged: (value) {
                                                setState(
                                                  () => selectedStrokeWidth =
                                                      value,
                                                );
                                              },
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.orange.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    selectedStrokeWidth
                                                        .toInt()
                                                        .toString(),
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors
                                                          .orange
                                                          .shade900,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: resetStrokeWidth,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.orange.shade300,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Reset Width',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _compactToolButton(
                    icon: Icons.image,
                    color: Colors.pinkAccent,
                    tooltip: 'Add Image',
                    onPressed: _pickImageFromGallery,
                  ),
                  const SizedBox(height: 8),
                  _compactToolButton(
                    icon: Icons.emoji_emotions,
                    color: Colors.orangeAccent,
                    tooltip: 'Add Emoji',
                    onPressed: _showEmojiPicker,
                  ),
                ],
              ),
            ),
          ),
          // Bottom compact controls
          Positioned(
            bottom: 16,
            left: 16,
            right: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _bottomIconButton(
                    icon: Icons.undo,
                    color: Colors.green,
                    onPressed: undo,
                  ),
                  _bottomIconButton(
                    icon: Icons.redo,
                    color: Colors.purple,
                    onPressed: redo,
                  ),
                  _bottomIconButton(
                    icon: Icons.delete_sweep,
                    color: Colors.red,
                    onPressed: clearCanvas,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactToolButton({
    required IconData icon,
    required Color color,
    Color? iconColor,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: iconColor ?? Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _bottomIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        insertedImages.add(
          CanvasImage(
            file: File(pickedFile.path),
            position: Offset(
              MediaQuery.of(context).size.width / 2 - 100,
              MediaQuery.of(context).size.height / 2 - 100,
            ),
            scale: 1.0,
          ),
        );
      });
    }
  }

  Widget _shapeIcon(ToolShape shape) {
    switch (shape) {
      case ToolShape.line:
        return const Icon(Icons.show_chart, size: 24);
      case ToolShape.rectangle:
        return const Icon(Icons.crop_5_4, size: 24);
      case ToolShape.square:
        return const Icon(Icons.crop_square, size: 24);
      case ToolShape.circle:
        return const Icon(Icons.circle, size: 24);
      case ToolShape.triangle:
        return const Icon(Icons.change_history, size: 24);
      case ToolShape.pentagon:
      case ToolShape.polygon5:
        return const Icon(Icons.star_rate, size: 24);
      case ToolShape.hexagon:
      case ToolShape.polygon6:
        return const Icon(Icons.hexagon, size: 24);
      case ToolShape.octagon:
      case ToolShape.polygon8:
        return const Icon(Icons.stop, size: 24);
      case ToolShape.star:
        return const Icon(Icons.star, size: 24);
      case ToolShape.heart:
        return const Icon(Icons.favorite, size: 24);
      case ToolShape.arrow:
        return const Icon(Icons.arrow_right_alt, size: 24);
      case ToolShape.diamond:
        return const Icon(Icons.diamond, size: 24);
      case ToolShape.cloud:
        return const Icon(Icons.cloud, size: 24);
      case ToolShape.semicircle:
        return const Icon(Icons.circle_outlined, size: 24);
      case ToolShape.crescent:
        return const Icon(Icons.brightness_3, size: 24);
      default:
        return const SizedBox();
    }
  }

  Widget _lineIcon(LineStyle style) {
    switch (style) {
      case LineStyle.solid:
        return const Icon(Icons.linear_scale, size: 18);
      case LineStyle.dotted:
        return const Icon(Icons.more_horiz, size: 18);
      case LineStyle.dashed:
        return const Icon(Icons.remove, size: 18);
    }
  }

  Widget _topBarButton(String text, Color color, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: TextButton(
          onPressed: onTap,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final Color backgroundColor;

  _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    this.backgroundColor = Colors.white, // default
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background first
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    for (var stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    Paint paint = Paint()
      ..color = stroke.color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke.strokeWidth
      ..style = PaintingStyle.stroke;

    if (stroke.shape == ToolShape.line) {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.lineStyle == LineStyle.dotted && i % 2 != 0) continue;
        if (stroke.lineStyle == LineStyle.dashed && i % 5 != 0) continue;
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    } else if (stroke.points.length > 1) {
      final p1 = stroke.points.first;
      final p2 = stroke.points.last;
      switch (stroke.shape) {
        case ToolShape.rectangle:
          canvas.drawRect(Rect.fromPoints(p1, p2), paint);
          break;
        case ToolShape.square:
          double size = math.max((p2.dx - p1.dx).abs(), (p2.dy - p1.dy).abs());
          canvas.drawRect(Rect.fromLTWH(p1.dx, p1.dy, size, size), paint);
          break;
        case ToolShape.circle:
          double radius = (p2 - p1).distance / 2;
          Offset center = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
          canvas.drawCircle(center, radius, paint);
          break;
        case ToolShape.triangle:
          Offset p3 = Offset(p2.dx, p1.dy);
          Path path = Path()
            ..moveTo(p1.dx, p1.dy)
            ..lineTo(p3.dx, p3.dy)
            ..lineTo(p2.dx, p2.dy)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case ToolShape.pentagon:
        case ToolShape.polygon5:
          _drawPolygon(canvas, p1, p2, 5, paint);
          break;
        case ToolShape.hexagon:
        case ToolShape.polygon6:
          _drawPolygon(canvas, p1, p2, 6, paint);
          break;
        case ToolShape.octagon:
        case ToolShape.polygon8:
          _drawPolygon(canvas, p1, p2, 8, paint);
          break;
        case ToolShape.star:
          _drawStar(canvas, p1, p2, 5, paint);
          break;
        case ToolShape.heart:
          _drawHeart(canvas, p1, p2, paint);
          break;
        case ToolShape.arrow:
          _drawArrow(canvas, p1, p2, paint);
          break;
        case ToolShape.diamond:
          _drawDiamond(canvas, p1, p2, paint);
          break;
        case ToolShape.cloud:
          _drawCloud(canvas, p1, p2, paint);
          break;
        case ToolShape.ellipse:
          canvas.drawOval(Rect.fromPoints(p1, p2), paint);
          break;
        case ToolShape.semicircle:
          _drawSemiCircle(canvas, p1, p2, paint);
          break;
        case ToolShape.crescent:
          _drawCrescent(canvas, p1, p2, paint);
          break;
        case ToolShape.line:
        case ToolShape.none:
          break;
      }
    }
  }

  void _drawPolygon(
    Canvas canvas,
    Offset p1,
    Offset p2,
    int sides,
    Paint paint,
  ) {
    double radius = (p2 - p1).distance / 2;
    Offset center = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    Path path = Path();
    for (int i = 0; i < sides; i++) {
      double x =
          center.dx + radius * math.cos(2 * math.pi * i / sides - math.pi / 2);
      double y =
          center.dy + radius * math.sin(2 * math.pi * i / sides - math.pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset p1, Offset p2, int points, Paint paint) {
    double radius = (p2 - p1).distance / 2;
    Offset center = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    Path path = Path();
    for (int i = 0; i < points * 2; i++) {
      double r = i.isEven ? radius : radius / 2;
      double angle = i * math.pi / points - math.pi / 2;
      double x = center.dx + r * math.cos(angle);
      double y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    double width = (p2.dx - p1.dx).abs();
    double height = (p2.dy - p1.dy).abs();
    Path path = Path();
    path.moveTo(p1.dx + width / 2, p1.dy + height);
    path.cubicTo(
      p1.dx - width / 2,
      p1.dy + height / 2,
      p1.dx + width / 2,
      p1.dy - height / 3,
      p1.dx + width / 2,
      p1.dy + height / 3,
    );
    canvas.drawPath(path, paint);
  }

  void _drawArrow(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    canvas.drawLine(p1, p2, paint);
    double arrowSize = 10;
    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    final path = Path();
    path.moveTo(p2.dx, p2.dy);
    path.lineTo(
      p2.dx - arrowSize * math.cos(angle - math.pi / 6),
      p2.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    path.moveTo(p2.dx, p2.dy);
    path.lineTo(
      p2.dx - arrowSize * math.cos(angle + math.pi / 6),
      p2.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    canvas.drawPath(path, paint);
  }

  void _drawDiamond(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    Offset center = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    Path path = Path();
    path.moveTo(center.dx, p1.dy);
    path.lineTo(p2.dx, center.dy);
    path.lineTo(center.dx, p2.dy);
    path.lineTo(p1.dx, center.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCloud(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    double w = (p2.dx - p1.dx).abs();
    double h = (p2.dy - p1.dy).abs();
    Path path = Path();
    path.addOval(
      Rect.fromCircle(
        center: Offset(p1.dx + w * 0.3, p1.dy + h * 0.5),
        radius: h * 0.25,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(p1.dx + w * 0.5, p1.dy + h * 0.3),
        radius: h * 0.25,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(p1.dx + w * 0.7, p1.dy + h * 0.5),
        radius: h * 0.25,
      ),
    );
    path.addRect(
      Rect.fromLTWH(p1.dx + w * 0.3, p1.dy + h * 0.5, w * 0.4, h * 0.2),
    );
    canvas.drawPath(path, paint);
  }

  void _drawSemiCircle(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    double radius = (p2 - p1).distance / 2;
    Offset center = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi,
      false,
      paint,
    );
  }

  void _drawCrescent(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    double radius = (p2 - p1).distance / 2;
    Offset center = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    canvas.drawCircle(center, radius, paint);
    Paint backgroundPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      center.translate(radius * 0.3, 0),
      radius,
      backgroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
