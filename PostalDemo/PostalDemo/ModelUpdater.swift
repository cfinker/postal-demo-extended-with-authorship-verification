/*
https://developer.apple.com/documentation/coreml/core_ml_api/personalizing_a_model_with_on-device_updates
 
Abstract:
Manager responsible for updating and using the correct Drawing Classifier at runtime.
*/

import CoreML

/// Class that handles predictions and updating of UpdatableDrawingClassifier model.
struct ModelUpdater {
    // MARK: - Private Type Properties
    /// The updated Drawing Classifier model.
    private static var updatedKNN: UpdatableKNN?
    /// The default Drawing Classifier model.
    private static let defaultKNN = UpdatableKNN()

    // The Drawing Classifier model currently in use.
    private static var liveModel: UpdatableKNN {
        updatedKNN ?? defaultKNN
    }
    
    /// The location of the app's Application Support directory for the user.
    private static let appDirectory = FileManager.default.urls(for: .applicationSupportDirectory,
                                                               in: .userDomainMask).first!
    
    /// The default Drawing Classifier model's file URL.
    private static let defaultModelURL = UpdatableKNN.urlOfModelInThisBundle
    /// The permanent location of the updated Drawing Classifier model.
    private static var updatedModelURL = appDirectory.appendingPathComponent("personalized.mlmodelc")
    /// The temporary location of the updated Drawing Classifier model.
    private static var tempUpdatedModelURL = appDirectory.appendingPathComponent("personalized_tmp.mlmodelc")
    
    /// Triggers code on the first prediction, to (potentially) load a previously saved updated model just-in-time.
    private static var hasMadeFirstPrediction = false
    
    /// The Model Updater type doesn't use instances of itself.
    private init() { }
    
    // MARK: - Public Type Methods
    static func predictLabelFor(_ value: MLMultiArray) -> String? {
        do {
            if !hasMadeFirstPrediction {
                hasMadeFirstPrediction = true
                
                // Load the updated model the app saved on an earlier run, if available.
                loadUpdatedModel()
            }
            let prediction = try liveModel.prediction(input: value);
            let outputLabel = prediction.output
            print(prediction.outputProbs)
            return outputLabel;
        } catch let error {
            print("Could not do some prediction: \(error)")
            return nil
        }
    }
    
    /// Updates the model to recognize images simlar to the given drawings contained within the `inputBatchProvider`.
    /// - Parameters:
    ///     - trainingData: A collection of sample images, each paired with the same label.
    ///     - completionHandler: The completion handler provided from a view controller.
    /// - Tag: CreateUpdateTask
    static func updateWith(trainingData: MLBatchProvider,
                           completionHandler: @escaping () -> Void) {
        
        /// The URL of the currently active Drawing Classifier.
        let usingUpdatedModel = updatedKNN != nil
        let currentModelURL = usingUpdatedModel ? updatedModelURL : defaultModelURL
        
        /// The closure an MLUpdateTask calls when it finishes updating the model.
        func updateModelCompletionHandler(updateContext: MLUpdateContext) {
            // Save the updated model to the file system.
            saveUpdatedModel(updateContext)
            
            // Begin using the saved updated model.
            loadUpdatedModel()
            
            // Inform the calling View Controller when the update is complete
            DispatchQueue.main.async { completionHandler() }
        }
        
        self.updateModel(at: currentModelURL,
                        with: trainingData,
                        completionHandler: updateModelCompletionHandler)
    }
    
    static func updateModel(at url: URL,
                               with trainingData: MLBatchProvider,
                               completionHandler: @escaping (MLUpdateContext) -> Void) {
           
           // Create an Update Task.
           guard let updateTask = try? MLUpdateTask(forModelAt: url,
                                              trainingData: trainingData,
                                              configuration: nil,
                                              completionHandler: completionHandler)
               else {
                   print("Could't create an MLUpdateTask.")
                   return
           }
           
           updateTask.resume()
    }
    
    /// Deletes the updated model and reverts back to original Drawing Classifier.
    static func resetDrawingClassifier() {
        // Clear the updated Drawing Classifier.
        updatedKNN = nil
        
        // Remove the updated model from its designated path.
        if FileManager.default.fileExists(atPath: updatedModelURL.path) {
            try? FileManager.default.removeItem(at: updatedModelURL)
        }
    }
    
    // MARK: - Private Type Helper Methods
    /// Saves the model in the given Update Context provided by an MLUpdateTask.
    /// - Parameter updateContext: The context from the Update Task that contains the updated model.
    /// - Tag: SaveUpdatedModel
    private static func saveUpdatedModel(_ updateContext: MLUpdateContext) {
        let updatedModel = updateContext.model
        let fileManager = FileManager.default
        do {
            // Create a directory for the updated model.
            try fileManager.createDirectory(at: tempUpdatedModelURL,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
            
            // Save the updated model to temporary filename.
            try updatedModel.write(to: tempUpdatedModelURL)
            
            // Replace any previously updated model with this one.
            _ = try fileManager.replaceItemAt(updatedModelURL,
                                              withItemAt: tempUpdatedModelURL)
            
            print("Updated model saved to:\n\t\(updatedModelURL)")
        } catch let error {
            print("Could not save updated model to the file system: \(error)")
            return
        }
    }
    
    /// Loads the updated Drawing Classifier, if available.
    /// - Tag: LoadUpdatedModel
    private static func loadUpdatedModel() {
        guard FileManager.default.fileExists(atPath: updatedModelURL.path) else {
            // The updated model is not present at its designated path.
            return
        }
        
        // Create an instance of the updated model.
        guard let model = try? UpdatableKNN(contentsOf: updatedModelURL) else {
            return
        }
        
        // Use this updated model to make predictions in the future.
        updatedKNN = model
    }
}
