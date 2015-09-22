fs = require 'fs'
path = require 'path'
_ = require 'underscore-plus'

module.exports = (grunt) ->
  {spawn} = require('./task-helpers')(grunt)

  getInstalledSize = (buildDir, callback) ->
    cmd = 'du'
    args = ['-sk', path.join(buildDir, 'Atom')]
    spawn {cmd, args}, (error, {stdout}) ->
      installedSize = stdout.split(/\s+/)?[0] or '200000' # default to 200MB
      callback(null, installedSize)

  fillTemplate = (filePath, data, outputPath) ->
    content = _.template(String(fs.readFileSync("#{filePath}.in")))(data)
    grunt.file.write(outputPath, content)

  grunt.registerTask 'mkdeb', 'Create debian package', ->
    done = @async()

    if process.arch is 'ia32'
      arch = 'i386'
    else if process.arch is 'x64'
      arch = 'amd64'
    else
      return done("Unsupported arch #{process.arch}")

    appName = grunt.config.get('atom.appName')
    buildDir = grunt.config.get('atom.buildDir')
    channel = grunt.config.get('atom.channel')
    appFileName = grunt.config.get('atom.appFileName')
    apmFileName = grunt.config.get('atom.apmFileName')
    {version, description} = grunt.config.get('atom.metadata')

    section = 'devel'
    maintainer = 'GitHub <atom@github.com>'
    installDir = '/usr'
    iconName = 'atom'

    executable = path.join(installDir, 'share', 'atom', 'atom')
    controlFilePath = path.join(buildDir, 'control')
    desktopFilePath = path.join(buildDir, appFileName + '.desktop')
    iconPath = path.join('resources', 'app-icons', channel, 'png', '1024.png')

    getInstalledSize buildDir, (error, installedSize) ->
      data = {
        appName, appFileName, apmFileName, version, description, section, arch,
        maintainer, installDir, iconName, installedSize, executable
      }

      fillTemplate(path.join('resources', 'linux', 'atom.desktop'), data, desktopFilePath)
      fillTemplate(path.join('resources', 'linux', 'debian', 'control'), data, controlFilePath)

      cmd = path.join('script', 'mkdeb')
      args = [version, channel, arch, controlFilePath, desktopFilePath, iconPath, buildDir]
      spawn {cmd, args}, (error) ->
        if error?
          done(error)
        else
          grunt.log.ok "Created #{buildDir}/atom-#{version}-#{arch}.deb"
          done()
