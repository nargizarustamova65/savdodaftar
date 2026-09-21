import 'package:flutter/material.dart';

/// Yagona spacing shkalasi — barcha ekranlarda bir xil ishlatiladi.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Ekran chetidagi gorizontal padding.
  static const double screen = 16;
}

/// Burchak radiuslari — TZ: rounded cards, 12–18px.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 18;

  static const BorderRadius field = BorderRadius.all(Radius.circular(md));
  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius large = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(xl));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(100));
}

/// Juda yengil shadow — TZ: "soft shadows, minimal shadow".
abstract final class AppShadows {
  static const List<BoxShadow> soft = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F101828),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> raised = <BoxShadow>[
    BoxShadow(
      color: Color(0x14101828),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
