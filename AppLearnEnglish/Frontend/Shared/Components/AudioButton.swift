//
//  AudioButton.swift
//  AppLearnEnglish
//

import SwiftUI

struct AudioButton: View {
    let isPlaying: Bool
    let action: () -> Void
    
    @State private var waveScale1: CGFloat = 1.0
    @State private var waveScale2: CGFloat = 1.0
    
    var body: some View {
        if #available(iOS 17.0, *) {
            Button(action: action) {
                ZStack {
                    // Expanding wave rings when playing
                    if isPlaying {
                        Circle()
                            .stroke(AppTheme.pastelSky.opacity(0.3), lineWidth: 2)
                            .frame(width: 80, height: 80)
                            .scaleEffect(waveScale1)
                            .opacity(Double(2.0 - waveScale1))
                            .onAppear {
                                withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                                    waveScale1 = 2.0
                                }
                            }
                        
                        Circle()
                            .stroke(AppTheme.pastelSky.opacity(0.2), lineWidth: 2)
                            .frame(width: 80, height: 80)
                            .scaleEffect(waveScale2)
                            .opacity(Double(2.0 - waveScale2))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                                        waveScale2 = 2.0
                                    }
                                }
                            }
                    }
                    
                    // Base Button Circle
                    Circle()
                        .fill(AppTheme.pastelSky.opacity(0.15))
                        .frame(width: 72, height: 72)
                    
                    Circle()
                        .fill(AppTheme.pastelSky)
                        .frame(width: 60, height: 60)
                        .shadow(color: AppTheme.pastelSky.opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onChange(of: isPlaying) { _, playing in
                if !playing {
                    waveScale1 = 1.0
                    waveScale2 = 1.0
                }
            }
        } else {
            // Fallback on earlier versions
        };if #available(iOS 17.0, *) {
            Button(action: action) {
                ZStack {
                    // Expanding wave rings when playing
                    if isPlaying {
                        Circle()
                            .stroke(AppTheme.pastelSky.opacity(0.3), lineWidth: 2)
                            .frame(width: 80, height: 80)
                            .scaleEffect(waveScale1)
                            .opacity(Double(2.0 - waveScale1))
                            .onAppear {
                                withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                                    waveScale1 = 2.0
                                }
                            }
                        
                        Circle()
                            .stroke(AppTheme.pastelSky.opacity(0.2), lineWidth: 2)
                            .frame(width: 80, height: 80)
                            .scaleEffect(waveScale2)
                            .opacity(Double(2.0 - waveScale2))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                                        waveScale2 = 2.0
                                    }
                                }
                            }
                    }
                    
                    // Base Button Circle
                    Circle()
                        .fill(AppTheme.pastelSky.opacity(0.15))
                        .frame(width: 72, height: 72)
                    
                    Circle()
                        .fill(AppTheme.pastelSky)
                        .frame(width: 60, height: 60)
                        .shadow(color: AppTheme.pastelSky.opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onChange(of: isPlaying) { _, playing in
                if !playing {
                    waveScale1 = 1.0
                    waveScale2 = 1.0
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        AudioButton(isPlaying: false) {}
        AudioButton(isPlaying: true) {}
    }
    .padding()
}
