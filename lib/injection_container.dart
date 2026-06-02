import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/update_profile_usecase.dart';
import 'features/auth/domain/usecases/reset_password_usecase.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

import 'core/config/push_config.dart';
import 'core/network/push_api_client.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/utils/push_debug.dart';
import 'features/main/data/datasources/notification_remote_data_source.dart';
import 'features/main/data/datasources/wallet_remote_data_source.dart';
import 'features/main/data/datasources/budget_remote_data_source.dart';
import 'features/main/data/repositories/wallet_repository_impl.dart';
import 'features/main/data/repositories/budget_repository_impl.dart';
import 'features/main/domain/repositories/wallet_repository.dart';
import 'features/main/domain/repositories/budget_repository.dart';
import 'features/main/domain/usecases/deposit_usecase.dart';
import 'features/main/domain/usecases/get_primary_wallet_stream_usecase.dart';
import 'features/main/domain/usecases/transfer_out_usecase.dart';
import 'features/main/domain/usecases/get_transactions_stream_usecase.dart';
import 'features/main/domain/usecases/transfer_to_user_usecase.dart';
import 'features/main/domain/usecases/watch_out_categories_usecase.dart';
import 'features/main/presentation/cubit/budget_cubit.dart';
import 'features/group_wallet/data/datasources/group_wallet_remote_data_source.dart';
import 'features/group_wallet/data/repositories/group_wallet_repository_impl.dart';
import 'features/group_wallet/domain/repositories/group_wallet_repository.dart';
import 'features/group_wallet/domain/usecases/accept_invitation_usecase.dart';
import 'features/group_wallet/domain/usecases/close_group_wallet_usecase.dart';
import 'features/group_wallet/domain/usecases/contribute_to_group_usecase.dart';
import 'features/group_wallet/domain/usecases/create_group_wallet_usecase.dart';
import 'features/group_wallet/domain/usecases/invite_member_usecase.dart';
import 'features/group_wallet/domain/usecases/reject_invitation_usecase.dart';
import 'features/group_wallet/domain/usecases/remind_debt_usecase.dart';
import 'features/group_wallet/domain/usecases/remove_member_usecase.dart';
import 'features/group_wallet/domain/usecases/settle_debt_usecase.dart';
import 'features/group_wallet/domain/usecases/split_expense_usecase.dart';
import 'features/group_wallet/domain/usecases/watch_debts_usecase.dart';
import 'features/group_wallet/domain/usecases/watch_group_transactions_usecase.dart';
import 'features/group_wallet/domain/usecases/watch_group_wallet_detail_usecase.dart';
import 'features/group_wallet/domain/usecases/watch_group_wallets_usecase.dart';
import 'features/group_wallet/domain/usecases/watch_pending_invitations_usecase.dart';
import 'features/group_wallet/domain/usecases/withdraw_from_group_usecase.dart';
import 'features/group_wallet/presentation/cubit/group_wallet_cubit.dart';

final sl = GetIt.instance; // sl: Service Locator

Future<void> init() async {
  // Firebase initialization must be done before anything else. It's usually done in main()
  // but we provide instances here

  // External
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  // Features - Auth
  // Cubit
  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl(),
      registerUseCase: sl(),
      updateProfileUseCase: sl(),
      resetPasswordUseCase: sl(),
      pushNotificationService: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl(), firestore: sl()),
  );
  sl.registerLazySingleton(() => NotificationRemoteDataSource(firestore: sl()));

  //! Features - Wallet
  sl.registerLazySingleton(() => DepositUseCase(sl()));
  sl.registerLazySingleton(() => GetPrimaryWalletStreamUseCase(sl()));
  sl.registerLazySingleton(() => TransferOutUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsStreamUseCase(sl()));
  sl.registerLazySingleton(() => TransferToUserUseCase(sl()));
  sl.registerLazySingleton(() => WatchOutCategoriesUseCase(sl(), sl()));

  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<CreateGroupWalletUseCase>(
    () => CreateGroupWalletUseCase(sl()),
  );
  sl.registerLazySingleton<WatchGroupWalletsUseCase>(
    () => WatchGroupWalletsUseCase(sl()),
  );
  sl.registerLazySingleton<WatchGroupWalletDetailUseCase>(
    () => WatchGroupWalletDetailUseCase(sl()),
  );
  sl.registerLazySingleton<CloseGroupWalletUseCase>(
    () => CloseGroupWalletUseCase(sl()),
  );
  sl.registerLazySingleton<InviteMemberUseCase>(
    () => InviteMemberUseCase(sl()),
  );
  sl.registerLazySingleton<AcceptInvitationUseCase>(
    () => AcceptInvitationUseCase(sl()),
  );
  sl.registerLazySingleton<RejectInvitationUseCase>(
    () => RejectInvitationUseCase(sl()),
  );
  sl.registerLazySingleton<RemoveMemberUseCase>(
    () => RemoveMemberUseCase(sl()),
  );
  sl.registerLazySingleton<ContributeToGroupUseCase>(
    () => ContributeToGroupUseCase(sl()),
  );
  sl.registerLazySingleton<WithdrawFromGroupUseCase>(
    () => WithdrawFromGroupUseCase(sl()),
  );
  sl.registerLazySingleton<SplitExpenseUseCase>(
    () => SplitExpenseUseCase(sl()),
  );
  sl.registerLazySingleton<SettleDebtUseCase>(() => SettleDebtUseCase(sl()));
  sl.registerLazySingleton<RemindDebtUseCase>(
    () => RemindDebtUseCase(sl(), sl()),
  );
  sl.registerLazySingleton(() => PushApiClient());
  sl.registerLazySingleton<WatchGroupTransactionsUseCase>(
    () => WatchGroupTransactionsUseCase(sl()),
  );
  sl.registerLazySingleton<WatchDebtsUseCase>(() => WatchDebtsUseCase(sl()));
  sl.registerLazySingleton<WatchPendingInvitationsUseCase>(
    () => WatchPendingInvitationsUseCase(sl()),
  );

  sl.registerLazySingleton<GroupWalletRepository>(
    () => GroupWalletRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<GroupWalletRemoteDataSource>(
    () => GroupWalletRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<BudgetRemoteDataSource>(
    () => BudgetRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory(
    () => BudgetCubit(
      getPrimaryWalletStreamUseCase: sl(),
      budgetRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => GroupWalletCubit(
      createGroupWalletUseCase: sl(),
      watchGroupWalletsUseCase: sl(),
      watchGroupWalletDetailUseCase: sl(),
      closeGroupWalletUseCase: sl(),
      inviteMemberUseCase: sl(),
      acceptInvitationUseCase: sl(),
      rejectInvitationUseCase: sl(),
      removeMemberUseCase: sl(),
      contributeToGroupUseCase: sl(),
      withdrawFromGroupUseCase: sl(),
      splitExpenseUseCase: sl(),
      settleDebtUseCase: sl(),
      remindDebtUseCase: sl(),
      watchGroupTransactionsUseCase: sl(),
      watchDebtsUseCase: sl(),
      watchPendingInvitationsUseCase: sl(),
    ),
  );

  //! Core Services
  final localNotif = LocalNotificationService();
  await localNotif.init();
  sl.registerLazySingleton(() => localNotif);

  final pushNotif = PushNotificationService(
    messaging: FirebaseMessaging.instance,
    firestore: sl(),
    localNotificationService: localNotif,
  );
  await pushNotif.init();
  sl.registerLazySingleton(() => pushNotif);

  if (PushConfig.isConfigured) {
    PushDebug.ok('PUSH_WORKER_URL', PushConfig.workerUrl);
  } else {
    PushDebug.warn(
      'PUSH_WORKER_URL',
      'Chưa cấu hình — chỉ có inbox Firestore, không push OS',
    );
  }

  //! Core

  //! External
}
