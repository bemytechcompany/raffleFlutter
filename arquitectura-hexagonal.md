---
description: Reglas de arquitectura hexagonal, organización feature-first y sistema de colores unificado para el proyecto
alwaysApply: true
---

# Arquitectura y Estilo - RaffleFlutter

## 🏗️ Arquitectura Clean Architecture

Estoy desarrollando una app de rifas en Flutter utilizando la arquitectura Clean Architecture, manejo de estado con Bloc, y persistencia local con SQLite (sqflite).

### Estructura general del proyecto:

```bash
lib/
├── core/
│   ├── db/
│   │   └── database_provider.dart
│   ├── theme/
│   │   ├── app_colors.dart           # ✨ Colores unificados
│   │   ├── app_theme.dart            # ✨ Tema principal
│   │   ├── button_styles.dart        # ✨ Estilos de botones
│   │   └── theme_guide.md            # ✨ Guía de mejores prácticas
│   └── widgets/
│       └── keyboard_dismissible.dart
├── features/
│   ├── raffles/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── raffle_local_datasource.dart
│   │   │   │   └── ticket_dao.dart
│   │   │   ├── models/
│   │   │   │   ├── raffle_model.dart
│   │   │   │   └── ticket_model.dart
│   │   │   └── repositories/
│   │   │       └── raffle_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── raffle.dart
│   │   │   │   └── ticket.dart
│   │   │   └── repositories/
│   │   │       └── raffle_repository.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── raffle_bloc.dart
│   │       │   ├── raffle_event.dart
│   │       │   └── raffle_state.dart
│   │       ├── bloc/details/
│   │       │   ├── raffle_details_bloc.dart
│   │       │   ├── raffle_details_event.dart
│   │       │   └── raffle_details_state.dart
│   │       ├── pages/
│   │       │   ├── raffle_list_page.dart
│   │       │   ├── raffle_create_page.dart
│   │       │   └── raffle_details_page.dart
│   │       └── widgets/
│   │           ├── ticket_grid.dart
│   │           ├── ticket_modal.dart
│   │           ├── ticket_info_modal.dart
│   │           └── financial_summary.dart
│   └── giveaways/
│       └── [misma estructura que raffles]
└── layout/
    └── main_layout.dart
```

## 📋 Reglas de Arquitectura

### ✅ OBLIGATORIO:

1. **Repositorios**: Deben cumplir con la interfaz del domain
2. **Models**: Deben extender de sus entities o tener métodos `.fromEntity()` y `.toEntity()`
3. **Datasources**: Todas las operaciones con SQLite se realizan aquí
4. **Compatibilidad**: Todo el flujo debe ser compatible con Android e iOS
5. **Bloc Pattern**: Manejo de estado exclusivamente con Bloc
6. **Feature-First**: Organización por características, no por capas

## 🎨 Sistema de Colores y Temas Unificado

### ✅ USAR SIEMPRE:

#### 1. AppColors para todos los colores
```dart
// ✅ CORRECTO
Container(
  color: AppColors.buttonGreenBackground,
  child: Text(
    'Texto',
    style: TextStyle(color: AppColors.buttonGreenForeground),
  ),
)

// ❌ INCORRECTO - No usar colores hardcodeados
Container(
  color: Colors.green,  // ❌ MAL
  child: Text(
    'Texto',
    style: TextStyle(color: Colors.white),  // ❌ MAL
  ),
)
```

#### 2. ButtonStyles para botones consistentes
```dart
// ✅ CORRECTO - Usar estilos predefinidos
ElevatedButton(
  style: ButtonStyles.greenActiveButton,
  onPressed: () {},
  child: Text('Crear'),
)

// ✅ CORRECTO - Tema automático para casos simples
ElevatedButton(
  onPressed: () {},
  child: Text('Guardar'),
)

// ❌ INCORRECTO - No repetir estilos
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,  // ❌ MAL
    foregroundColor: Colors.white,
  ),
  onPressed: () {},
  child: Text('Crear'),
)
```

#### 3. Importar siempre los archivos de tema
```dart
// ✅ OBLIGATORIO en archivos de UI
import 'package:raffle/core/theme/app_colors.dart';
import 'package:raffle/core/theme/button_styles.dart';
```

### 📚 Paleta de Colores Disponibles:

#### Botones Principales (Verde Activo)
- `AppColors.buttonGreenBackground` - Fondo verde vibrante
- `AppColors.buttonGreenForeground` - Texto blanco
- `AppColors.buttonGreenBorder` - Borde verde oscuro

#### Estados de Éxito
- `AppColors.success` - Mensajes de éxito
- `AppColors.raffleActive` - Rifas activas
- `AppColors.giveawayCompleted` - Sorteos completados

#### Backgrounds
- `AppColors.background` - Fondo principal (negro)
- `AppColors.backgroundCard` - Fondo de tarjetas
- `AppColors.backgroundModal` - Fondo de modales

#### Textos
- `AppColors.text` - Texto principal (blanco)
- `AppColors.textBlack` - Texto negro
- `AppColors.textSecondary` - Texto secundario

### 🎯 Jerarquía de Uso de Estilos:

1. **Tema por defecto** (sin style explícito) - Para casos simples
2. **ButtonStyles.xxx** - Para botones con estilos predefinidos
3. **AppColors específicos** - Para casos que requieren personalización

## 🚫 PROHIBICIONES ESTRICTAS:

### ❌ NO usar nunca:
```dart
// ❌ Colores hardcodeados
Colors.green
Colors.white
Colors.black
Color(0xFF4CAF50)

// ❌ Estilos repetitivos inline
ElevatedButton.styleFrom(
  backgroundColor: Colors.green,
  foregroundColor: Colors.white,
  // ... más código repetitivo
)
```

### ✅ USAR en su lugar:
```dart
// ✅ Variables de AppColors
AppColors.buttonGreenBackground
AppColors.text
AppColors.success

// ✅ Estilos predefinidos
ButtonStyles.greenActiveButton
ButtonStyles.greenActiveButtonWithRadius(12)
```

## 📱 Ejemplo de Widget Completo y Correcto:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/button_styles.dart';
import '../bloc/raffle_bloc.dart';

class MyRaffleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundCard,
      child: Column(
        children: [
          // Título
          Text(
            'Mi Rifa',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Botón principal - usa tema automático
          ElevatedButton(
            onPressed: () {
              context.read<RaffleBloc>().add(CreateRaffle());
            },
            child: Text('Crear Rifa'),
          ),
          
          // Botón secundario - usa estilo predefinido
          ElevatedButton(
            onPressed: () {},
            style: ButtonStyles.greenActiveButtonWithRadius(20),
            child: Text('Confirmar'),
          ),
          
          // Estado exitoso
          Container(
            color: AppColors.success.withOpacity(0.1),
            child: Text(
              'Rifa creada exitosamente',
              style: TextStyle(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
```

## 🔍 Checklist de Desarrollo:

Antes de cualquier commit, verificar:

### Arquitectura:
- [ ] ¿Los repositories implementan las interfaces del domain?
- [ ] ¿Los models tienen métodos fromEntity/toEntity?
- [ ] ¿Las operaciones DB están en datasources?
- [ ] ¿Se usa Bloc para el estado?

### Colores y Tema:
- [ ] ¿Se importa `app_colors.dart` en archivos de UI?
- [ ] ¿No hay colores hardcodeados (Colors.green, etc)?
- [ ] ¿Se usan ButtonStyles para botones consistentes?
- [ ] ¿Los estilos siguen la jerarquía: tema > ButtonStyles > AppColors?

## 📚 Referencias:

- `lib/core/theme/theme_guide.md` - Guía completa de colores y temas
- `lib/core/theme/app_colors.dart` - Definición de todos los colores
- `lib/core/theme/button_styles.dart` - Estilos de botones reutilizables

**¡Mantén SIEMPRE la consistencia arquitectónica y visual!** 