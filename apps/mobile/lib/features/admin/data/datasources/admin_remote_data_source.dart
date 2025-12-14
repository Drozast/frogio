import '../models/municipal_statistics_model.dart';
import '../models/query_model.dart';
import '../models/user_model.dart';

abstract class AdminRemoteDataSource {
  /// Obtiene todas las consultas pendientes
  Future<List<QueryModel>> getAllPendingQueries(String muniId);
  
  /// Responde a una consulta
  Future<void> answerQuery(
    String queryId, 
    String response, 
    String responderId, {
    required String adminId,
    List<String>? attachments,
  });
  
  /// Obtiene las estadísticas municipales
  Future<MunicipalStatisticsModel> getMunicipalStatistics(String muniId);
  
  /// Obtiene todos los usuarios del municipio
  Future<List<UserModel>> getAllUsers(String muniId);
  
  /// Obtiene usuarios por rol específico
  Future<List<UserModel>> getUsersByRole({
    required String muniId, 
    required String role,
  });
  
  /// Actualiza el rol de un usuario
  Future<void> updateUserRole(String userId, String newRole);
  
  /// Actualiza el estado de un usuario
  Future<void> updateUserStatus(String userId, bool isActive);
}