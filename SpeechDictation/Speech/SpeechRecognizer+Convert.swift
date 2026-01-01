//
//  SpeechRecognizer+Convert.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/29/24.
//

import Foundation
import AudioToolbox

extension SpeechRecognizer {
    func convertMP3ToM4A(mp3URL: URL, completion: @escaping (URL?) -> Void) {
        let outputURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("m4a")
        
        var inputFile: ExtAudioFileRef? = nil
        var outputFile: ExtAudioFileRef? = nil
        
        var inputDesc = AudioStreamBasicDescription()
        var outputDesc = AudioStreamBasicDescription()
        
        // Open the input file
        var status: OSStatus = ExtAudioFileOpenURL(mp3URL as CFURL, &inputFile)
        if status != noErr {
            AppLog.error(.export, "Error opening input file: \(status)")
            completion(nil)
            return
        }
        
        // Get the input file's format
        var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        status = ExtAudioFileGetProperty(inputFile!, kExtAudioFileProperty_FileDataFormat, &size, &inputDesc)
        if status != noErr {
            AppLog.error(.export, "Error getting input file format: \(status)")
            ExtAudioFileDispose(inputFile!)
            completion(nil)
            return
        }
        
        // Set the output file's format
        outputDesc.mSampleRate = 44100
        outputDesc.mFormatID = kAudioFormatMPEG4AAC
        outputDesc.mChannelsPerFrame = 2
        outputDesc.mFramesPerPacket = 1024
        outputDesc.mBytesPerPacket = 0
        outputDesc.mBytesPerFrame = 0
        outputDesc.mBitsPerChannel = 0
        outputDesc.mReserved = 0
        
        // Create the output file
        status = ExtAudioFileCreateWithURL(outputURL as CFURL, kAudioFileM4AType, &outputDesc, nil, AudioFileFlags.eraseFile.rawValue, &outputFile)
        if status != noErr {
            AppLog.error(.export, "Error creating output file: \(status)")
            ExtAudioFileDispose(inputFile!)
            completion(nil)
            return
        }
        
        // Set the output file's client format to PCM
        var clientFormat = AudioStreamBasicDescription()
        clientFormat.mSampleRate = 44100
        clientFormat.mFormatID = kAudioFormatLinearPCM
        clientFormat.mFormatFlags = kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger
        clientFormat.mFramesPerPacket = 1
        clientFormat.mChannelsPerFrame = 2
        clientFormat.mBitsPerChannel = 16
        clientFormat.mBytesPerFrame = clientFormat.mBitsPerChannel / 8 * clientFormat.mChannelsPerFrame
        clientFormat.mBytesPerPacket = clientFormat.mBytesPerFrame * clientFormat.mFramesPerPacket
        clientFormat.mReserved = 0
        
        // Set the client format for input and output files
        status = ExtAudioFileSetProperty(inputFile!, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat)
        if status != noErr {
            AppLog.error(.export, "Error setting input file client format: \(status)")
            ExtAudioFileDispose(inputFile!)
            ExtAudioFileDispose(outputFile!)
            completion(nil)
            return
        }
        
        status = ExtAudioFileSetProperty(outputFile!, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat)
        if status != noErr {
            AppLog.error(.export, "Error setting output file client format: \(status)")
            ExtAudioFileDispose(inputFile!)
            ExtAudioFileDispose(outputFile!)
            completion(nil)
            return
        }
        
        // Create a buffer and read the data
        let bufferByteSize: UInt32 = 32768
        var buffer = [UInt8](repeating: 0, count: Int(bufferByteSize))
        var convertedData = AudioBufferList(
            mNumberBuffers: 1,
            mBuffers: AudioBuffer(
                mNumberChannels: clientFormat.mChannelsPerFrame,
                mDataByteSize: bufferByteSize,
                mData: &buffer
            )
        )
        
        var totalFrames: UInt64 = 0
        var completedFrames: UInt64 = 0
        
        while true {
            var frameCount: UInt32 = bufferByteSize / clientFormat.mBytesPerFrame
            status = ExtAudioFileRead(inputFile!, &frameCount, &convertedData)
            if status != noErr || frameCount == 0 {
                break
            }
            status = ExtAudioFileWrite(outputFile!, frameCount, &convertedData)
            if status != noErr {
                AppLog.error(.export, "Error writing to output file: \(status)")
                ExtAudioFileDispose(inputFile!)
                ExtAudioFileDispose(outputFile!)
                completion(nil)
                return
            }
            completedFrames += UInt64(frameCount)
            totalFrames = UInt64(inputDesc.mSampleRate) * UInt64(inputDesc.mFramesPerPacket)
            if totalFrames > 0 {
                let progress = Double(completedFrames) / Double(totalFrames)
                if Int(progress * 100) % 10 == 0 {
                    AppLog.debug(
                        .export,
                        "Conversion progress: \(Int(progress * 100))%",
                        dedupeInterval: 0.5,
                        verboseOnly: true
                    )
                }
            }
        }
        
        ExtAudioFileDispose(inputFile!)
        ExtAudioFileDispose(outputFile!)
        
        if status == noErr {
            AppLog.info(.export, "Successfully converted MP3 to M4A: \(outputURL)")
            completion(outputURL)
        } else {
            AppLog.error(.export, "Error during conversion: \(status)")
            completion(nil)
        }
    }
    
}
