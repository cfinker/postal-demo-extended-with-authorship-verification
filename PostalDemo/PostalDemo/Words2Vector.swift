//
//  Words2Vector.swift
//  PostalDemo
//
//  Created by Christian Finker on 20.10.19.
//  Copyright © 2019 Snips. All rights reserved.
//

import CoreML
import Foundation
import NaturalLanguage

class Words2Vector {
    
    func createSelectedFeaturesVector(text: String) -> MLMultiArray {
    
        var vectorDoubleArray = Array(repeating: 0.0, count: 21)
        
        let tagger = NLTagger(tagSchemes: [NLTagScheme.tokenType, NLTagScheme.lexicalClass, NLTagScheme.language,  NLTagScheme.sentimentScore])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        let lexicalClassCounterArray = self.getLexicalClassValues(text: text, tagger: tagger, options: options);
        let tokeTypeCounterArray = self.getTokenValues(text: text, tagger: tagger, options: options);
        let langaugeCounterArray = self.getLanguageValues(text: text, tagger: tagger, options: options);
        let sentimentScoreSingleValue = self.getSentimentScore(text: text, tagger: tagger);

        let lexicalClassValuesDict = self.transfromCounterValuesInRealtiveValues(counterArray: lexicalClassCounterArray, documentLength: self.getNumberOfWords(str: text))
        let tokeTypeValuesDict = self.transfromCounterValuesInRealtiveValues(counterArray: tokeTypeCounterArray, documentLength: self.getNumberOfWords(str: text))
        let langaugeValuesDict = self.transfromCounterValuesInRealtiveValues(counterArray: langaugeCounterArray, documentLength: self.getNumberOfWords(str: text))
        
        // lexical Values
        vectorDoubleArray[0] = Double(lexicalClassValuesDict["noun"] ?? 0);
        vectorDoubleArray[1] = Double(lexicalClassValuesDict["verb"] ?? 0);
        vectorDoubleArray[2] = Double(lexicalClassValuesDict["adjective"] ?? 0);
        vectorDoubleArray[3] = Double(lexicalClassValuesDict["adverb"] ?? 0);
        vectorDoubleArray[4] = Double(lexicalClassValuesDict["pronoun"] ?? 0);
        vectorDoubleArray[5] = Double(lexicalClassValuesDict["determiner"] ?? 0);
        vectorDoubleArray[6] = Double(lexicalClassValuesDict["preposition"] ?? 0);
        vectorDoubleArray[7] = Double(lexicalClassValuesDict["number"] ?? 0);
        vectorDoubleArray[8] = Double(lexicalClassValuesDict["conjunction"] ?? 0);
        vectorDoubleArray[9] = Double(lexicalClassValuesDict["interjection"] ?? 0);
        vectorDoubleArray[10] = Double(lexicalClassValuesDict["classifier"] ?? 0);
        vectorDoubleArray[11] = Double(lexicalClassValuesDict["idiom"] ?? 0);
        vectorDoubleArray[12] = Double(lexicalClassValuesDict["otherWord"] ?? 0);
        
        // token types
        vectorDoubleArray[13] = Double(tokeTypeValuesDict["word"] ?? 0);
        vectorDoubleArray[14] = Double(tokeTypeValuesDict["punctuation"] ?? 0);
        vectorDoubleArray[15] = Double(tokeTypeValuesDict["whitespace"] ?? 0);
        vectorDoubleArray[16] = Double(tokeTypeValuesDict["other"] ?? 0);

        // language (consider only english and german)
        vectorDoubleArray[17] = Double(langaugeValuesDict["en"] ?? 0);
        vectorDoubleArray[18] = Double(langaugeValuesDict["de"] ?? 0);
        
        // sentiment score
        vectorDoubleArray[19] = sentimentScoreSingleValue

        //average sentence length
        vectorDoubleArray[20] = Double(self.getNumberOfWords(str: text)/self.getNumberOfSentences(input: text))
        
        print(vectorDoubleArray)

        return convertToMLArray(vectorDoubleArray)
    }
    
    func getNumberOfSentences(input: String) -> Int {
        // from https://stackoverflow.com/questions/49800315/how-can-i-count-the-number-of-sentences-in-a-given-text-in-swift
        let charset = CharacterSet(charactersIn: ".?,!")
        let arr = input.components(separatedBy: charset)
        if(arr.count - 1 < 1) {
            return 1
        }
        return arr.count - 1
    }
    
    func getNumberOfWords(str: String) -> Int {
           // from https://stackoverflow.com/questions/42822838/how-to-get-the-number-of-real-words-in-a-text-in-swift
           let chararacterSet = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
           let components = str.components(separatedBy: chararacterSet)
           let words = components.filter { !$0.isEmpty }
          return words.count;
       }
    
    func transfromCounterValuesInRealtiveValues(counterArray: [String: Int], documentLength: Int) -> [String: Double] {
        var counterDict: [String: Double] = [:]
        for (key,value) in counterArray {
            counterDict[key] = Double(value)/Double(documentLength);
        }
        return counterDict;
    }
    
    func getLexicalClassValues(text: String, tagger: NLTagger, options: NLTagger.Options) -> [String: Int] {
        // from https://developer.apple.com/documentation/naturallanguage/identifying_parts_of_speech
        var lexicalClassCounterArray: [String: Int] = [:]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            if let tag = tag {
                if(lexicalClassCounterArray[tag.rawValue.lowercased()] == nil) {
                    lexicalClassCounterArray[tag.rawValue.lowercased()] = 0;
                }
                lexicalClassCounterArray[tag.rawValue.lowercased()]! += 1
            }
            return true
        }
        return lexicalClassCounterArray;
    }
    
    func getTokenValues(text: String, tagger: NLTagger, options: NLTagger.Options) -> [String: Int] {
        var tokeTypeCounterArray: [String: Int] = [:]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .tokenType, options: options) { tag, tokenRange in
            if let tag = tag {
                if(tokeTypeCounterArray[tag.rawValue.lowercased()] == nil) {
                    tokeTypeCounterArray[tag.rawValue.lowercased()] = 0;
                }
                tokeTypeCounterArray[tag.rawValue.lowercased()]! += 1
            }
            return true
        }
        return tokeTypeCounterArray;
    }
    
    func getLanguageValues(text: String, tagger: NLTagger, options: NLTagger.Options) -> [String: Int] {
        var langaugeCounterArray: [String: Int] = [:]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .language, options: options) { tag, tokenRange in
            if let tag = tag {
                if(langaugeCounterArray[tag.rawValue.lowercased()] == nil) {
                    langaugeCounterArray[tag.rawValue.lowercased()] = 0;
                }
                langaugeCounterArray[tag.rawValue.lowercased()]! += 1
            }
            return true
        }
        return langaugeCounterArray;
    }
    
    func getSentimentScore(text: String, tagger: NLTagger) -> Double {
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .document, scheme: .sentimentScore)
        return Double(sentiment?.rawValue ?? "0") ?? 0
    }
    
    func convertToMLArray(_ data: [Double]) -> MLMultiArray {

        guard let mlMultiArray = try? MLMultiArray(shape:[21], dataType:MLMultiArrayDataType.double) else {
            fatalError("Unexpected runtime error. MLMultiArray")
        }
        
        for (index, element) in data.enumerated() {
            mlMultiArray[index] = NSNumber(floatLiteral: element)
        }
        
        print(mlMultiArray)
        
        return mlMultiArray;
    }
    
}
