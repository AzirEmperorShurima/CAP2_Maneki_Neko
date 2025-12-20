import 'package:finance_management_app/core/network/api_result.dart';
import 'package:finance_management_app/features/domain/entities/family_analytics_summary_model.dart';
import 'package:finance_management_app/features/domain/entities/family_invite_model.dart';
import 'package:finance_management_app/features/domain/entities/family_join_model.dart';
import 'package:finance_management_app/features/domain/entities/family_model.dart';
import 'package:finance_management_app/features/domain/entities/family_top_categories_model.dart';
import 'package:finance_management_app/features/domain/entities/family_top_wallets_model.dart';
import 'package:finance_management_app/features/domain/entities/family_user_breakdown_model.dart';

abstract class FamilyRepository {
  Future<ApiResult<FamilyModel?>> getFamily();
  
  Future<ApiResult<FamilyInviteModel>> inviteToFamily(String email);

  Future<ApiResult<FamilyJoinModel>> joinFamily(String familyCode);

  Future<ApiResult<FamilyModel?>> createFamily(String name);

  Future<ApiResult<FamilyAnalyticsSummaryModel?>> getFamilyAnalyticsSummary();

  Future<ApiResult<FamilyUserBreakdownModel?>> getFamilyUserBreakdown();

  Future<ApiResult<FamilyTopCategoriesModel?>> getFamilyTopCategories();

  Future<ApiResult<FamilyTopWalletsModel?>> getFamilyTopWallets();
}
