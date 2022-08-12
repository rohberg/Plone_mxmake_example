let apps = [
    {
      name   : "plone_backend_tutorial",
      script: 'venv/bin/runwsgi instance/etc/zope.ini',
      cwd: 'backend'
    },
    // {
    //   name   : "plone_frontend_tutorial",
    //   script: 'yarn build && yarn start:prod',
    //   cwd: 'frontend'
    // }
  ];

module.exports = { apps: apps };
