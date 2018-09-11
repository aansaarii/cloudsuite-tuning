import sys

from matplotlib import pyplot, rc
import numpy
import parsers


def plot_single_side_graph(x_data, single_graph_data, plotter, ylim=None):
    plots = []
    if single_graph_data['type'] == 'plot':
        plots.extend(plotter.plot(
            x_data, single_graph_data['data'], single_graph_data['format'],
            label=single_graph_data['label']
        ))
    elif single_graph_data['type'] == 'errorbar':
        plots.append(plotter.errorbar(
            x_data, single_graph_data['data'], single_graph_data['error'],
            linestyle='None', marker='.', capsize=3, label=single_graph_data['label']
        ))

    limited_x_data = []
    limited_y_data = []
    if ylim is not None:
        for i in range(len(x_data)):
            if not single_graph_data['data'][i] > ylim:
                limited_x_data.append(x_data[i])
                limited_y_data.append(single_graph_data['data'][i])
    else:
        limited_x_data = x_data
        limited_y_data = single_graph_data['data']

    if single_graph_data['trend_line']:
        z = numpy.polyfit(limited_x_data, limited_y_data, 2)
        p = numpy.poly1d(z)
        x_data = sorted(x_data)
        plots.extend(plotter.plot(
            x_data,
            p(x_data),
            single_graph_data['trend_line_format'],
            label=single_graph_data['label'] + ' trend'),
        )

    plotter.tick_params('y')
    return plots


def plot_graphs(graph_data, output_file_name):
    """
    This function plots the parsed graph from logs.
    :param output_file_name: this parameter is the path to output image file
    :param graph_data: the data should be in a format like the following:
    graph_data = {
        'graphs': [
                {
                    'x': x_data,
                    'x_label': 'Requests Per Second',
                    'y': {
                        'left': [
                            {
                                'type': 'plot',
                                'format': 'b.',
                                'data': utilizations,
                                'error': utilization_errors,
                                'label': 'Server CPU Utilization',
                            }
                        ],
                        'left_label': 'Server CPU Utilization (%)',
                        'right': [
                            {
                                'type': 'errorbar',
                                'data': tail_latencies_95th,
                                'error': tail_latency_95th_errors,
                                'label': '95th Latency (ms)',
                            },
                            {
                                'type': 'errorbar',
                                'data': tail_latencies_99th,
                                'error': tail_latency_99th_errors,
                                'label': '99th Latency (ms)',
                            },
                        ],
                        'right_label': 'Latency (ms)'
                    }
                }
            ],
        'dimensions': (1, 1)
    }
    """
    rc('font', size=24)
    pyplot.figure(figsize=graph_data['figure_size'])

    graph_counter = 1
    last_sub_plot = None

    for single_graph_data in graph_data['graphs']:
        left_plot = pyplot.subplot(
            graph_data['dimensions'][0],
            graph_data['dimensions'][1],
            graph_counter,
            sharex=last_sub_plot
        )
        if single_graph_data['y']['left_limit'] is not None:
            left_plot.set_ylim(bottom=0, top=single_graph_data['y']['left_limit'])
        left_plot.set_title(single_graph_data['title'])
        last_sub_plot = left_plot
        plots = []

        for single_left_graph in single_graph_data['y']['left']:
            plots.extend(plot_single_side_graph(
                single_graph_data['x'],
                single_left_graph, left_plot,
                ylim=single_graph_data['y']['left_limit']
            ))

        left_plot.set_ylabel(single_graph_data['y']['left_label'])
        left_plot.set_xlabel(single_graph_data['x_label'])

        if len(single_graph_data['y']['right']) > 0:
            right_plot = left_plot.twinx()
            if single_graph_data['y']['right_limit'] is not None:
                right_plot.set_ylim(bottom=0, top=single_graph_data['y']['right_limit'])
            for single_right_graph in single_graph_data['y']['right']:
                plots.extend(plot_single_side_graph(
                    single_graph_data['x'],
                    single_right_graph,
                    right_plot,
                    ylim=single_graph_data['y']['right_limit']
                ))

            right_plot.set_ylabel(single_graph_data['y']['right_label'])

        left_plot.legend(plots, [plot.get_label() for plot in plots], loc=0)

        graph_counter += 1

    pyplot.suptitle(graph_data['sup_title'])
    pyplot.tight_layout()
    pyplot.subplots_adjust(top=0.92)
    pyplot.savefig(output_file_name)


if len(sys.argv) < 3:
    print('Usage: python plotter.py [benchmark] [output_file_name] [file_names...]', file=sys.stderr)
    exit(1)

try:
    parse = getattr(parsers, 'parse_' + sys.argv[1])
    plot_graphs(parse(sys.argv[3:]), sys.argv[2])
except AttributeError:
    print('Undefined benchmark "{}".'.format(sys.argv[1]), file=sys.stderr)
