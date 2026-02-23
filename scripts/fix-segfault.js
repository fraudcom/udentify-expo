#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🔧 Applying segmentation fault fixes...');

// Fix 1: EXConstants.podspec
const constantsPodspecPath = path.join(__dirname, '../node_modules/expo-constants/ios/EXConstants.podspec');
if (fs.existsSync(constantsPodspecPath)) {
  let content = fs.readFileSync(constantsPodspecPath, 'utf8');
  if (content.includes('bash -l -c')) {
    content = content.replace(/bash -l -c/g, '/bin/bash -c');
    fs.writeFileSync(constantsPodspecPath, content);
    console.log('   ✅ Fixed EXConstants.podspec');
  } else {
    console.log('   ℹ️  EXConstants.podspec already fixed');
  }
} else {
  console.log('   ⚠️  EXConstants.podspec not found');
}

// Fix 2: Xcode project file
const projectFilePath = path.join(__dirname, '../ios/FraudExpoTest.xcodeproj/project.pbxproj');
if (fs.existsSync(projectFilePath)) {
  let content = fs.readFileSync(projectFilePath, 'utf8');
  if (content.includes('bash -l -c')) {
    const originalContent = content;
    content = content.replace(/bash -l -c/g, '/bin/bash -c');
    fs.writeFileSync(projectFilePath, content);
    
    // Count replacements
    const replacements = (originalContent.match(/bash -l -c/g) || []).length;
    console.log(`   ✅ Fixed Xcode project file (${replacements} replacement${replacements !== 1 ? 's' : ''})`);
  } else {
    console.log('   ℹ️  Xcode project file already fixed');
  }
} else {
  console.log('   ⚠️  Xcode project file not found');
}

console.log('🎉 Segmentation fault fixes applied!');
