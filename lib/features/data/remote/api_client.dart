import 'package:dio/dio.dart';
import 'package:finance_management_app/core/response/base_response.dart';
import 'package:finance_management_app/features/data/requests/google_login_request.dart';
import 'package:finance_management_app/features/data/requests/login_request.dart';
import 'package:finance_management_app/features/data/requests/register_request.dart';
import 'package:retrofit/retrofit.dart';

import '../requests/budget_request.dart';
import '../requests/category_request.dart';
import '../requests/chat_request.dart';
import '../requests/family_request.dart';
import '../requests/transaction_request.dart';
import '../requests/wallet_request.dart';
import '../requests/wallet_transfer_request.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) = _ApiClient;

  // Auth
  @POST('/auth/login')
  Future<BaseResponse> login(
    @Body() LoginRequest request,
  );

  @POST('/auth/login/verify/google-id')
  Future<BaseResponse> loginWithGoogle(
    @Body() GoogleLoginRequest request,
  );

  @POST('/auth/register')
  Future<BaseResponse> register(
    @Body() RegisterRequest request,
  );

  @POST('/auth/logout')
  Future<BaseResponse> logout();

  // User
  @GET('/user/profile')
  Future<BaseResponse> getMyProfile();

  // Transaction
  @GET('/transaction/transactions')
  Future<BaseResponse> getTransactions(
    @Query('type') String? type,
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('month') DateTime? month,
    @Query('walletId') String? walletId,
  );

  @POST('/transaction/transactions')
  Future<BaseResponse> createTransaction(
    @Body() TransactionRequest? request,
  );

  @PUT('/transaction/transactions/{id}')
  Future<BaseResponse> updateTransaction(
    @Path('id') String id,
    @Body() TransactionRequest? request,
  );

  @DELETE('/transaction/transactions/{id}')
  Future<BaseResponse> deleteTransaction(
    @Path('id') String id,
  );

  // Category
  @GET('/category')
  Future<BaseResponse> getCategories(
    @Query('type') String? type,
  );

  @POST('/category')
  Future<BaseResponse> createCategory(
    @Body() CategoryRequest? request,
  );

  @GET('/category/images')
  Future<BaseResponse> getCategoryImages(
    @Query('folder') String? folder,
    @Query('limit') int? limit,
    @Query('cursor') String? cursor,
  );

  // Wallet
  @GET('/wallet')
  Future<BaseResponse> getWallets();

  @POST('/wallet')
  Future<BaseResponse> createWallet(
    @Body() WalletRequest? request,
  );

  @PUT('/wallet/{id}')
  Future<BaseResponse> updateWallet(
    @Path('id') String id,
    @Body() WalletRequest? request,
  );

  @DELETE('/wallet/{id}')
  Future<BaseResponse> deleteWallet(
    @Path('id') String id,
  );

  @POST('/wallet/transfer')
  Future<BaseResponse> walletTransfer(
    @Body() WalletTransferRequest? request,
  );

  // Chat
  @POST('/chat/gemini')
  Future<BaseResponse> chatWithGemini(
    @Body() ChatRequest? request,
  );
  
  // Analytics
  @GET('/analytics/personal/overview')
  Future<BaseResponse> getPersonalOverview(
    @Query('includePeriodBreakdown') bool? includePeriodBreakdown,
    @Query('breakdownType') String? breakdownType,
    @Query('walletId') String? walletId,
    @Query('startDate') DateTime? startDate,
    @Query('endDate') DateTime? endDate,
  );

  @GET('/analytics/personal/wallet/{walletId}/details')
  Future<BaseResponse> getWalletAnalysis(
    @Path('walletId') String walletId,
  );
  
  @GET('/analytics/personal/by-category')
  Future<BaseResponse> getAnalysisCategories(
    @Query('type') String? type,
  );

  // Budget
  @GET('/budget')
  Future<BaseResponse> getBudgets();

  @POST('/budget')
  Future<BaseResponse> createBudget(
    @Body() BudgetRequest? request,
  );

  @PUT('/budget/{id}')
  Future<BaseResponse> updateBudget(
    @Path('id') String id,
    @Body() BudgetRequest? request,
  );

  @DELETE('/budget/{id}')
  Future<BaseResponse> deleteBudget(
    @Path('id') String id,
  );

  // Family
  @GET('/family/profile')
  Future<BaseResponse> getFamilies();

  @POST('/family')
  Future<BaseResponse> createFamily(
    @Body() FamilyCreateRequest request,
  );

  @POST('/family/invite')
  Future<BaseResponse> inviteToFamily(
    @Body() FamilyInviteRequest request,
  );

  @POST('/family/join-app')
  Future<BaseResponse> joinFamily(
    @Body() FamilyJoinRequest request,
  );

  @GET('/family/analytics/summary')
  Future<BaseResponse> getFamilyAnalyticsSummary();

  @GET('/family/analytics/user-breakdown')
  Future<BaseResponse> getFamilyUserBreakdown();

  @GET('/family/analytics/top-categories')
  Future<BaseResponse> getFamilyTopCategories();

  @GET('/family/analytics/top-spender')
  Future<BaseResponse> getFamilyTopWallets();
}