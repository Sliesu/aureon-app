//
//  BiometricAuthManager.swift
//  aureon-app
//
//  Face ID / Touch ID 二次确认，用于模拟下单与启用自动执行等敏感操作。
//  在无生物识别硬件（例如部分模拟器）时优雅降级为直接放行，避免阻塞演示。
//

import LocalAuthentication

@MainActor
final class BiometricAuthManager {
    enum Outcome {
        case authorized
        case unavailable
        case denied
    }

    func authorize(reasonZh: String) async -> Outcome {
        let context = LAContext()
        var evaluationError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &evaluationError) else {
            return .unavailable
        }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonZh)
            return success ? .authorized : .denied
        } catch {
            return .denied
        }
    }

    var biometryKindLabel: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "生物识别"
        }
    }
}
