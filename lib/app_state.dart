import 'database/app_database.dart';
import 'database_connection.dart';
import 'services/notification_service.dart';

/// Base de données partagée par l'application (initialisée dans main avant le premier frame).
late AppDatabase appDatabase;

/// Instance partagée du service de notifications (init dans main).
final notificationService = NotificationService();
