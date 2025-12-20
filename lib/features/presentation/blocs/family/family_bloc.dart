import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:finance_management_app/features/domain/entities/family_analytics_summary_model.dart';
import 'package:finance_management_app/features/domain/entities/family_invite_model.dart';
import 'package:finance_management_app/features/domain/entities/family_join_model.dart';
import 'package:finance_management_app/features/domain/entities/family_model.dart';
import 'package:finance_management_app/features/domain/entities/family_top_categories_model.dart';
import 'package:finance_management_app/features/domain/entities/family_top_wallets_model.dart';
import 'package:finance_management_app/features/domain/entities/family_user_breakdown_model.dart';
import 'package:finance_management_app/features/domain/repository/family_repository.dart';
import 'package:injectable/injectable.dart';

part 'family_event.dart';
part 'family_state.dart';

@injectable
class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  final FamilyRepository familyRepository;

  FamilyBloc(this.familyRepository) : super(FamilyInitial()) {
    on<LoadFamilySubmitted>(_onLoadFamilySubmitted);
    on<RefreshFamily>(_onRefreshFamily);
    on<ResetFamily>(_onResetFamily);
    on<InviteToFamilySubmitted>(_onInviteToFamilySubmitted);
    on<JoinFamilySubmitted>(_onJoinFamilySubmitted);
    on<CreateFamilySubmitted>(_onCreateFamilySubmitted);
    on<LoadFamilyAnalyticsSummary>(_onLoadFamilyAnalyticsSummary);
    on<LoadFamilyUserBreakdown>(_onLoadFamilyUserBreakdown);
    on<LoadFamilyTopCategories>(_onLoadFamilyTopCategories);
    on<LoadFamilyTopWallets>(_onLoadFamilyTopWallets);
  }

  Future<void> _onLoadFamilySubmitted(
    LoadFamilySubmitted event,
    Emitter<FamilyState> emit,
  ) async {
    final currentState = state;
    if (currentState is FamilyLoaded && currentState.family != null) {
      return;
    }

    emit(FamilyLoading());

    final result = await familyRepository.getFamily();

    result.when(
      success: (data) {
        emit(FamilyLoaded(data));
      },
      failure: (error) {
        // 404 = chưa có family, coi như success với null
        if (error.contains('Không tìm thấy gia đình') ||
            error.contains('Resource not found') ||
            error.contains('404')) {
          emit(FamilyLoaded(null));
        } else {
          emit(FamilyFailure(error));
        }
      },
    );
  }

  void _onResetFamily(
    ResetFamily event,
    Emitter<FamilyState> emit,
  ) {
    emit(FamilyInitial());
  }

  Future<void> _onRefreshFamily(
    RefreshFamily event,
    Emitter<FamilyState> emit,
  ) async {
    final currentState = state;
    if (currentState is FamilyLoaded) {
      emit(FamilyRefreshing(currentState.family));
    } else {
      emit(FamilyLoading());
    }

    final result = await familyRepository.getFamily();

    result.when(
      success: (data) {
        emit(FamilyLoaded(data));
      },
      failure: (error) {
        // 404 = chưa có family, coi như success với null
        if (error.contains('Không tìm thấy gia đình') ||
            error.contains('Resource not found') ||
            error.contains('404')) {
          emit(FamilyLoaded(null));
        } else {
          emit(FamilyFailure(error));
        }
      },
    );
  }

  Future<void> _onInviteToFamilySubmitted(
    InviteToFamilySubmitted event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyInviting());

    final result = await familyRepository.inviteToFamily(event.email);

    result.when(
      success: (inviteData) {
        emit(FamilyInvited(event.email, inviteData: inviteData));
        // Refresh family data after invite
        add(RefreshFamily());
      },
      failure: (error) {
        emit(FamilyInviteFailure(error));
      },
    );
  }

  Future<void> _onJoinFamilySubmitted(
    JoinFamilySubmitted event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyJoining());

    final result = await familyRepository.joinFamily(event.familyCode);

    result.when(
      success: (joinData) {
        emit(FamilyJoined(event.familyCode, joinData: joinData));
        // Refresh family data after join
        add(RefreshFamily());
      },
      failure: (error) {
        emit(FamilyJoinFailure(error));
      },
    );
  }

  Future<void> _onCreateFamilySubmitted(
    CreateFamilySubmitted event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyCreating());

    final result = await familyRepository.createFamily(event.name);

    result.when(
      success: (data) {
        if (data != null) {
          emit(FamilyCreated(data));
          add(RefreshFamily());
        } else {
          emit(FamilyCreateFailure('Không thể tạo gia đình'));
        }
      },
      failure: (error) {
        emit(FamilyCreateFailure(error));
      },
    );
  }

  Future<void> _onLoadFamilyAnalyticsSummary(
    LoadFamilyAnalyticsSummary event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyAnalyticsSummaryLoading());

    final result = await familyRepository.getFamilyAnalyticsSummary();

    result.when(
      success: (data) {
        emit(FamilyAnalyticsSummaryLoaded(data));
      },
      failure: (error) {
        emit(FamilyAnalyticsSummaryFailure(error));
      },
    );
  }

  Future<void> _onLoadFamilyUserBreakdown(
    LoadFamilyUserBreakdown event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyUserBreakdownLoading());

    final result = await familyRepository.getFamilyUserBreakdown();

    result.when(
      success: (data) {
        emit(FamilyUserBreakdownLoaded(data));
      },
      failure: (error) {
        emit(FamilyUserBreakdownFailure(error));
      },
    );
  }

  Future<void> _onLoadFamilyTopCategories(
    LoadFamilyTopCategories event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyTopCategoriesLoading());

    final result = await familyRepository.getFamilyTopCategories();

    result.when(
      success: (data) {
        emit(FamilyTopCategoriesLoaded(data));
      },
      failure: (error) {
        emit(FamilyTopCategoriesFailure(error));
      },
    );
  }

  Future<void> _onLoadFamilyTopWallets(
    LoadFamilyTopWallets event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyTopWalletsLoading());

    final result = await familyRepository.getFamilyTopWallets();

    result.when(
      success: (data) {
        emit(FamilyTopWalletsLoaded(data));
      },
      failure: (error) {
        emit(FamilyTopWalletsFailure(error));
      },
    );
  }
}
