fs = require 'fs'
path = require 'path'
_ = require 'underscore-plus'

module.exports = (grunt) ->
  {spawn, rm, mkdir} = require('./task-helpers')(grunt)

  fillTemplate = (filePath, data, outputPath) ->
    content = _.template(String(fs.readFileSync("#{filePath}.in")))(data)
    grunt.file.write(outputPath, content)

  grunt.registerTask 'mkrpm', 'Create rpm package', ->
    done = @async()

    if process.arch is 'ia32'
      arch = 'i386'
    else if process.arch is 'x64'
      arch = 'amd64'
    else
      return done("Unsupported arch #{process.arch}")

    buildDir = grunt.config.get('atom.buildDir')
    installDir = grunt.config.get('atom.installDir')
    appFileName = grunt.config.get('atom.appFileName')
    apmFileName = grunt.config.get('atom.apmFileName')
    {version, description} = grunt.config.get('atom.metadata')

    # RPM versions can't have dashes in them.
    # * http://www.rpm.org/max-rpm/ch-rpm-file-format.html
    # * https://github.com/mojombo/semver/issues/145
    version = version.replace(/-beta/, "~beta")
    version = version.replace(/-dev/, "~dev")

    rpmDir = path.join(buildDir, 'rpm')
    shareDir = path.join(installDir, 'share', appFileName)
    executable = path.join(shareDir, 'atom')
    specFilePath = path.join(buildDir, appFileName + '.spec')
    desktopFilePath = path.join(buildDir, appFileName + '.desktop')

    rm rpmDir
    mkdir rpmDir

    iconName = 'atom'
    data = {appFileName, apmFileName, version, description, installDir, iconName, executable}
    fillTemplate(path.join('resources', 'linux', 'redhat', 'atom.spec'), data, specFilePath)
    fillTemplate(path.join('resources', 'linux', 'atom.desktop'), data, desktopFilePath)

    cmd = path.join('script', 'mkrpm')
    args = [specFilePath, desktopFilePath, buildDir]
    spawn {cmd, args}, (error) ->
      if error?
        done(error)
      else
        grunt.log.ok "Created rpm package in #{rpmDir}"
        done()
