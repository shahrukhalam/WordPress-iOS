import Foundation
import Kanvas
import Photos

protocol CameraHandlerDelegate: class {
    func didCreateMedia(media: [Result<KanvasMedia?, Error>])
}

class KanvasService {
    weak var delegate: CameraHandlerDelegate?

    private static let useMetal = true

    static var cameraSettings: CameraSettings {
        let settings = CameraSettings()
        settings.features.ghostFrame = true
        settings.features.metalPreview = useMetal
        settings.features.metalFilters = useMetal
        settings.features.openGLPreview = !useMetal
        settings.features.openGLCapture = !useMetal
        settings.features.cameraFilters = false
        settings.features.experimentalCameraFilters = true
        settings.features.editor = true
        settings.features.editorGIFMaker = false
        settings.features.editorFilters = false
        settings.features.editorText = true
        settings.features.editorMedia = true
        settings.features.editorDrawing = false
        settings.features.editorMedia = false
        settings.features.mediaPicking = true
        settings.features.editorPostOptions = false
        settings.features.newCameraModes = true
        settings.features.gifs = false
        settings.features.multipleExports = true
        settings.crossIconInEditor = true
        settings.enabledModes = [.normal]
        settings.defaultMode = .normal
        settings.features.scaleMediaToFill = true
        settings.animateEditorControls = false
        settings.exportStopMotionPhotoAsVideo = false
        settings.fontSelectorUsesFont = true

        return settings
    }

    func controller(blog: Blog, context: NSManagedObjectContext, updated: @escaping (Result<(Post, [Media]), Error>) -> Void, uploaded: @escaping (Result<(Post, [Media]), Error>) -> Void) -> StoryEditor {
        let post = PostService(managedObjectContext: context).createDraftPost(for: blog)
        return controller(post: post, publishOnCompletion: true, updated: updated, uploaded: uploaded)
    }

    func controller(post: AbstractPost, publishOnCompletion: Bool = false, updated: @escaping (Result<(Post, [Media]), Error>) -> Void, uploaded: @escaping (Result<(Post, [Media]), Error>) -> Void) -> StoryEditor {
        KanvasColors.shared = KanvasCustomUI.shared.cameraColors()
        Kanvas.KanvasFonts.shared = KanvasCustomUI.shared.cameraFonts()
        let controller = StoryEditor(post: post,
                                     onClose: nil,
                                     settings: KanvasService.cameraSettings,
                                     stickerProvider: nil,
                                     analyticsProvider: KanvasAnalyticsStub(),
                                     quickBlogSelectorCoordinator: nil,
                                     tagCollection: nil,
                                     publishOnCompletion: publishOnCompletion,
                                     updated: updated,
                                     uploaded: uploaded)
        controller.delegate = self
        controller.modalPresentationStyle = .fullScreen
        controller.modalTransitionStyle = .crossDissolve
        return controller
    }
}

extension KanvasService: CameraControllerDelegate {

    func getQuickPostButton() -> UIView {
        return UIView()
    }

    func getBlogSwitcher() -> UIView {
        return UIView()
    }

    func didCreateMedia(_ cameraController: CameraController, media: [Result<KanvasMedia?, Error>], exportAction: KanvasExportAction) {
        delegate?.didCreateMedia(media: media)
    }

    func dismissButtonPressed(_ cameraController: CameraController) {
        if let editor = cameraController as? StoryEditor {
            editor.cancelEditing()
        } else {
            cameraController.dismiss(animated: true, completion: nil)
        }
    }

    func tagButtonPressed() {

    }

    func editorDismissed(_ cameraController: CameraController) {
        if let editor = cameraController as? StoryEditor {
            editor.cancelEditing()
        }
    }

    func didDismissWelcomeTooltip() {

    }

    func cameraShouldShowWelcomeTooltip() -> Bool {
        return false
    }

    func didDismissColorSelectorTooltip() {

    }

    func editorShouldShowColorSelectorTooltip() -> Bool {
        return true
    }

    func didEndStrokeSelectorAnimation() {

    }

    func editorShouldShowStrokeSelectorAnimation() -> Bool {
        return true
    }

    func provideMediaPickerThumbnail(targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            completion(nil)
        }
    }

    func didBeginDragInteraction() {

    }

    func didEndDragInteraction() {

    }

    func openAppSettings(completion: ((Bool) -> ())?) {

    }
}
