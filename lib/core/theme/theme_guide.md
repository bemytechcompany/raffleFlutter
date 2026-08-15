# Guía de Tema y Colores - RaffleFlutter

## 📋 Estructura de Archivos

```
lib/core/theme/
├── app_colors.dart      # Definición de todos los colores
├── app_theme.dart       # Configuración del tema principal
├── button_styles.dart   # Estilos de botones reutilizables
└── theme_guide.md       # Esta guía
```

## 🎨 Colores Principales

### Verde Activo (Botones Principales)
```dart
AppColors.buttonGreenBackground  // Fondo verde vibrante
AppColors.buttonGreenForeground  // Texto blanco
AppColors.buttonGreenBorder      // Borde verde oscuro
```

### Estados de Rifas y Sorteos
```dart
AppColors.raffleActive           // Verde para rifas activas
AppColors.giveawayCompleted      // Verde para sorteos completados
AppColors.success                // Verde para éxitos generales
```

### Colores de Texto
```dart
AppColors.text                   // Texto principal (blanco)
AppColors.textBlack              // Texto negro
AppColors.textSecondary          // Texto secundario
AppColors.textHint               // Texto de ayuda
```

## 🔧 Mejores Prácticas

### ✅ HACER
```dart
// Usar variables de AppColors
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.buttonGreenBackground,
    foregroundColor: AppColors.buttonGreenForeground,
  ),
  child: Text('Botón'),
)

// Usar estilos predefinidos
ElevatedButton(
  style: ButtonStyles.greenActiveButton,
  child: Text('Botón'),
)

// Usar tema cuando sea posible
ElevatedButton(
  // El tema ya aplica los estilos automáticamente
  child: Text('Botón'),
)
```

### ❌ NO HACER
```dart
// No usar colores hardcodeados
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,  // ❌ Mal
    foregroundColor: Colors.white,  // ❌ Mal
  ),
  child: Text('Botón'),
)

// No repetir estilos
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF4CAF50),  // ❌ Repetitivo
    foregroundColor: Colors.white,
    side: BorderSide(color: Color(0xFF388E3C)),
  ),
  child: Text('Botón'),
)
```

## 🎯 Cuándo Usar Cada Opción

### 1. Tema por Defecto
Para botones simples sin personalización especial:
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Botón'),
)
```

### 2. ButtonStyles
Para botones con estilos predefinidos:
```dart
ElevatedButton(
  onPressed: () {},
  style: ButtonStyles.greenActiveButton,
  child: Text('Botón'),
)
```

### 3. AppColors
Para casos específicos que requieren personalización:
```dart
Container(
  color: AppColors.buttonGreenBackground,
  child: Text(
    'Texto',
    style: TextStyle(color: AppColors.buttonGreenForeground),
  ),
)
```

## 🔄 Consistencia Visual

Todos los elementos verdes de la aplicación deben usar el mismo esquema:
- **Botones principales**: Verde activo
- **Estados exitosos**: Verde consistente
- **Confirmaciones**: Verde activo
- **Chips seleccionados**: Verde activo

## 📱 Ejemplo Completo

```dart
// Widget con tema consistente
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botón principal - usa tema automático
        ElevatedButton(
          onPressed: () {},
          child: Text('Crear'),
        ),
        
        // Botón personalizado - usa ButtonStyles
        ElevatedButton(
          onPressed: () {},
          style: ButtonStyles.greenActiveButtonWithRadius(20),
          child: Text('Confirmar'),
        ),
        
        // Texto con color específico
        Text(
          'Estado: Activo',
          style: TextStyle(color: AppColors.success),
        ),
        
        // Container con colores del tema
        Container(
          color: AppColors.backgroundCard,
          child: Text(
            'Contenido',
            style: TextStyle(color: AppColors.text),
          ),
        ),
      ],
    );
  }
}
```

## 🎨 Paleta de Colores Completa

### Verdes
- `buttonGreenBackground`: Fondo de botones principales
- `raffleActive`: Estado activo de rifas
- `giveawayCompleted`: Sorteos completados
- `success`: Mensajes de éxito

### Backgrounds
- `background`: Fondo principal (negro)
- `backgroundCard`: Fondo de tarjetas
- `backgroundModal`: Fondo de modales
- `backgroundInput`: Fondo de inputs

### Textos
- `text`: Texto principal (blanco)
- `textBlack`: Texto negro
- `textSecondary`: Texto secundario
- `textHint`: Texto de ayuda

¡Mantén esta guía actualizada cuando agregues nuevos colores o estilos! 