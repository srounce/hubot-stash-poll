expect = require('chai').expect
testContext = require('../test_context')
Broker = require('../../src/utils/broker')


describe 'utils | broker', ->
  context = {}

  beforeEach (done) ->
    testContext (testContext) ->
      context.robot = testContext.robot
      context.sandbox = testContext.sandbox
      context.user = testContext.user

      context.broker = new Broker(robot: context.robot)
      done()


  afterEach ->
    context.sandbox.restore()



  # =========================================================================
  #  .tryRegisterRepo()
  # =========================================================================
  describe '.tryRegisterRepo()', ->
    describe 'given an empty brain', ->
      it 'should save a new repo subscription to the brain', ->
        # when
        context.broker.tryRegisterRepo 'http://foo.com/', '#room'

        # then
        expect(context.robot.brain.data['stash-poll']['http://foo.com/'].api_url).to.eql 'http://foo.com/'
        expect(context.robot.brain.data['stash-poll']['http://foo.com/'].rooms).to.eql ['#room']


    describe 'given a non-empty brain', ->
      beforeEach ->
        context.robot.brain.data['stash-poll'] =
          'http://abc.com/':
            api_url: 'http://abc.com/'
            rooms: ['#abc']
          'http://mocha.com/':
            api_url: 'http://mocha.com/'
            rooms: ['#mocha']


      it 'should push the room to a repo if it doesn\'t already exist', ->
        # when
        context.broker.tryRegisterRepo 'http://abc.com/', '#mocha'

        # then
        expect(context.robot.brain.data['stash-poll']['http://abc.com/'].rooms).to.eql ['#abc','#mocha']


      it 'should not push the room to a repo if it already exists', ->
        # when
        context.broker.tryRegisterRepo 'http://abc.com/', '#mocha'

        # then
        expect(context.robot.brain.data['stash-poll']['http://mocha.com/'].rooms).to.eql ['#mocha']



  # =========================================================================
  #  .getNormalizedApiUrl()
  # =========================================================================
  describe '.getNormalizedApiUrl()', ->
    it 'should return null for invalid urls', ->
      for apiUrl in [undefined, null, 'xyz', 'foo.com', (->), {}, [], true, 3]
        expect(context.broker.getNormalizedApiUrl apiUrl).to.eql null


    it 'should trim whitespace for valid urls', ->
      expect(context.broker.getNormalizedApiUrl '  http://github.com/  ').to.eql 'http://github.com/'


    it 'should lower case the url', ->
      expect(context.broker.getNormalizedApiUrl 'HTTP://GITHUB.COM/').to.eql 'http://github.com/'



  # =========================================================================
  #  .getSubscribedReposFor()
  # =========================================================================
  describe '.getSubscribedReposFor()', ->
    it 'should return the repos that the room is subscribed to', ->
      # given
      context.robot.brain.data['stash-poll'] =
        'http://abc.com/':
          api_url: 'http://abc.com/'
          rooms: ['#mocha']
        'http://123.com/':
          api_url: 'http://123.com/'
          rooms: ['#mocha']

      # then
      repos = context.broker.getSubscribedReposFor '#mocha'

      expect(repos).to.eql [
        api_url: 'http://abc.com/'
        rooms: ['#mocha']
      ,
        api_url: 'http://123.com/'
        rooms: ['#mocha']
      ]


    it 'should not return the repos that the room is not subscribed to', ->
      # given
      context.robot.brain.data['stash-poll'] =
        'http://abc.com/':
          api_url: 'http://abc.com/'
          rooms: ['#notmocha']
        'http://123.com/':
          api_url: 'http://123.com/'
          rooms: ['#mocha']

      # then
      repos = context.broker.getSubscribedReposFor '#mocha'

      expect(repos).to.eql [
        api_url: 'http://123.com/'
        rooms: ['#mocha']
      ]

