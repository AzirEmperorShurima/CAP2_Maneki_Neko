import 'package:finance_management_app/features/domain/translator/family_analytics_summary_translator.dart';
import 'package:finance_management_app/features/domain/translator/family_invite_translator.dart';
import 'package:finance_management_app/features/domain/translator/family_join_translator.dart';
import 'package:finance_management_app/features/domain/translator/family_top_categories_translator.dart';
import 'package:finance_management_app/features/domain/translator/family_top_wallets_translator.dart';
import 'package:finance_management_app/features/domain/translator/family_translator.dart';
import 'package:finance_management_app/features/domain/translator/family_user_breakdown_translator.dart';
import 'package:injectable/injectable.dart';

import '../../../core/common/bases/base_repository.dart';
import '../../../core/network/api_result.dart';
import '../../domain/entities/family_analytics_summary_model.dart';
import '../../domain/entities/family_invite_model.dart';
import '../../domain/entities/family_join_model.dart';
import '../../domain/entities/family_model.dart';
import '../../domain/entities/family_top_categories_model.dart';
import '../../domain/entities/family_top_wallets_model.dart';
import '../../domain/entities/family_user_breakdown_model.dart';
import '../../domain/repository/family_repository.dart';
import '../remote/api_client.dart';
import '../requests/family_request.dart';
import '../response/family_analytics_summary_response.dart';
import '../response/family_invite_response.dart';
import '../response/family_join_response.dart';
import '../response/family_response.dart';
import '../response/family_top_categories_response.dart';
import '../response/family_top_wallets_response.dart';
import '../response/family_user_breakdown_response.dart';

@LazySingleton(as: FamilyRepository)
class FamilyRepositoryImpl extends BaseRepository implements FamilyRepository {
  final ApiClient apiClient;

  FamilyRepositoryImpl(this.apiClient);

  @override
  Future<ApiResult<FamilyModel?>> getFamily() {
    return handleApiResponse<FamilyModel?>(
      () async {
        final response = await apiClient.getFamilies();

        final familyResponse = response.getBody(
          FamilyResponse.fromJson,
        )?.toFamilyModel();

        return familyResponse;
      },
    );
  }

  @override
  Future<ApiResult<FamilyInviteModel>> inviteToFamily(String email) {
    return handleApiResponse<FamilyInviteModel>(
      () async {
        final request = FamilyInviteRequest(email: email);
        final response = await apiClient.inviteToFamily(request);

        final inviteResponse = response.getBody(
          FamilyInviteResponse.fromJson,
        )?.toFamilyInviteModel();

        if (inviteResponse == null) {
          throw Exception('Không thể parse response từ server');
        }

        return inviteResponse;
      },
    );
  }

  @override
  Future<ApiResult<FamilyJoinModel>> joinFamily(String familyCode) {
    return handleApiResponse<FamilyJoinModel>(
      () async {
        final request = FamilyJoinRequest(familyCode: familyCode);
        final response = await apiClient.joinFamily(request);

        final joinResponse = response.getBody(
          FamilyJoinResponse.fromJson,
        )?.toFamilyJoinModel();

        if (joinResponse == null) {
          throw Exception('Không thể parse response từ server');
        }

        return joinResponse;
      },
    );
  }

  @override
  Future<ApiResult<FamilyModel?>> createFamily(String name) {
    return handleApiResponse<FamilyModel?>(
      () async {
        final request = FamilyCreateRequest(name: name);
        final response = await apiClient.createFamily(request);

        final familyResponse = response.getBody(
          FamilyResponse.fromJson,
        )?.toFamilyModel();

        return familyResponse;
      },
    );
  }

  @override
  Future<ApiResult<FamilyAnalyticsSummaryModel?>> getFamilyAnalyticsSummary() {
    return handleApiResponse<FamilyAnalyticsSummaryModel?>(
      () async {
        final response = await apiClient.getFamilyAnalyticsSummary();

        final analyticsResponse = response.getBody(
          FamilyAnalyticsSummaryResponse.fromJson,
        )?.toFamilyAnalyticsSummaryModel();

        return analyticsResponse;
      },
    );
  }

  @override
  Future<ApiResult<FamilyUserBreakdownModel?>> getFamilyUserBreakdown() {
    return handleApiResponse<FamilyUserBreakdownModel?>(
      () async {
        final response = await apiClient.getFamilyUserBreakdown();

        final breakdownResponse = response.getBody(
          FamilyUserBreakdownResponse.fromJson,
        )?.toFamilyUserBreakdownModel();

        return breakdownResponse;
      },
    );
  }

  @override
  Future<ApiResult<FamilyTopCategoriesModel?>> getFamilyTopCategories() {
    return handleApiResponse<FamilyTopCategoriesModel?>(
      () async {
        final response = await apiClient.getFamilyTopCategories();

        final categoriesResponse = response.getBody(
          FamilyTopCategoriesResponse.fromJson,
        )?.toFamilyTopCategoriesModel();

        return categoriesResponse;
      },
    );
  }

  @override
  Future<ApiResult<FamilyTopWalletsModel?>> getFamilyTopWallets() {
    return handleApiResponse<FamilyTopWalletsModel?>(
      () async {
        final response = await apiClient.getFamilyTopWallets();

        final walletsResponse = response.getBody(
          FamilyTopWalletsResponse.fromJson,
        )?.toFamilyTopWalletsModel();

        return walletsResponse;
      },
    );
  }
}
