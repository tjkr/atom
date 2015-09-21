path = require 'path'
_ = require 'underscore-plus'
fs = require 'fs-plus'
runas = null
temp = require 'temp'

module.exports = (grunt) ->
  {cp, mkdir, rm} = require('./task-helpers')(grunt)

  grunt.registerTask 'install', 'Install the built application', ->
    installDir = grunt.config.get('atom.installDir')
    shellAppDir = grunt.config.get('atom.shellAppDir')
    appName = grunt.config.get('atom.appName')

    if process.platform is 'win32'
      runas ?= require 'runas'
      copyFolder = path.resolve 'script', 'copy-folder.cmd'
      if runas('cmd', ['/c', copyFolder, shellAppDir, installDir], admin: true) isnt 0
        grunt.log.error("Failed to copy #{shellAppDir} to #{installDir}")

      createShortcut = path.resolve 'script', 'create-shortcut.cmd'
      runas('cmd', ['/c', createShortcut, path.join(installDir, 'atom.exe'), appName])
    else if process.platform is 'darwin'
      rm installDir
      mkdir path.dirname(installDir)

      tempFolder = temp.path()
      mkdir tempFolder
      cp shellAppDir, tempFolder
      fs.renameSync(tempFolder, installDir)
    else
      binDir = path.join(installDir, 'bin')
      appDirName = appName.toLowerCase().replace(/\s+/g, '-')
      shareDir = path.join(installDir, 'share', appDirName)

      mkdir binDir
      cp 'atom.sh', path.join(binDir, 'atom')
      rm shareDir
      mkdir path.dirname(shareDir)
      cp shellAppDir, shareDir

      # Create atom.desktop if installation not in temporary folder
      tmpDir = if process.env.TMPDIR? then process.env.TMPDIR else '/tmp'
      if installDir.indexOf(tmpDir) isnt 0
        desktopFile = path.join('resources', 'linux', 'atom.desktop.in')
        desktopInstallFile = path.join(installDir, 'share', 'applications', appDirName + '.desktop')

        {description} = grunt.file.readJSON('package.json')
        iconName = path.join(shareDir, 'resources', 'app.asar.unpacked', 'resources', 'atom.png')
        executable = path.join(shareDir, 'atom')
        template = _.template(String(fs.readFileSync(desktopFile)))
        filled = template({description, iconName, executable})

        grunt.file.write(desktopInstallFile, filled)

      # Create relative symbol link for apm.
      process.chdir(binDir)
      rm('apm')
      fs.symlinkSync(path.join('..', 'share', appDirName, 'resources', 'app', 'apm', 'node_modules', '.bin', 'apm'), 'apm')

      fs.chmodSync(path.join(shareDir, 'atom'), "755")
