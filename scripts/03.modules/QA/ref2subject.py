import sys 
import numpy

if len(sys.argv)!=3:
  print "SYNTAX: ref2subject [transform_file] [x,y,z]"
  print ""
  sys.exit()

tfmfile=sys.argv[1]
pt=sys.argv[2]

def readITKtransform( transform_file ):
	'''
	'''
	 
	# read the transform
	transform = None
	with open( transform_file, 'r' ) as f:
	  for line in f:
	 
	    # check for Parameters:
	    if line.startswith( 'Parameters:' ):
	      values = line.split( ': ' )[1].split( ' ' )
	 
	      # filter empty spaces and line breaks
	      values = [float( e ) for e in values if ( e != '' and e != '\n' )]
	      # create the upper left of the matrix
	      transform_upper_left = numpy.reshape( values[0:9], ( 3, 3 ) )
	      # grab the translation as well
	      translation = values[9:]
	 
	    # check for FixedParameters:
	    if line.startswith( 'FixedParameters:' ):
	      values = line.split( ': ' )[1].split( ' ' )
	 
	      # filter empty spaces and line breaks
	      values = [float( e ) for e in values if ( e != '' and e != '\n' )]
	      # setup the center
	      center = values
	 
	# compute the offset
	offset = numpy.ones( 4 )
	for i in range( 0, 3 ):
	  offset[i] = translation[i] + center[i];
	  for j in range( 0, 3 ):
	    offset[i] -= transform_upper_left[i][j] * center[i]
	 
	# add the [0, 0, 0] line
	transform = numpy.vstack( ( transform_upper_left, [0, 0, 0] ) )
	# and the [offset, 1] column
	transform = numpy.hstack( ( transform, numpy.reshape( offset, ( 4, 1 ) ) ) )
	 
	return transform

t=readITKtransform(tfmfile)

ptcoord = pt.split( ',' )
if len(ptcoord) != 3:
  print "Error. Invalid point. Should be X,Y,Z"
  sys.exit(1)

ptcoord = [float( e ) for e in ptcoord ]


#print "Transform:"
#print t
#print "Point:"
##print ptcoord
p=ptcoord + [1.0]
#print p

r=numpy.dot(t,p)
print str(r[0])+","+str(r[1])+","+str(r[2])

