import boto3

def lambda_handler(event, context):

    # set the region to the region the event occured in
    region=event['region']
    instances=[event['detail']['i-0af49ba720d8d2a86']]

    print 'detected stopped instance : ' + str(instances)
    ec2 = boto3.client('ec2', region_name=region)
    ec2.start_instances(InstanceIds=instances)
    print 'started your instances: ' + str(instances)
