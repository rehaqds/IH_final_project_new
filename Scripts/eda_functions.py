import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

plt.style.use('fivethirtyeight')


def data_exploration(df, n_rows=5, categ_cols=None):
    """ Basic data exploration. """
    display(df.head(n_rows))
    print()
    df.info()
    print('\n\nDuplicates:', sum(df.duplicated()), '\n') # subset=['xxx']))
    if categ_cols is None:
        display(df.describe(include='all').T)
    else:
        display(df[categ_cols].describe(include='all').T)
        display(df[[col for col in df.columns if col not in categ_cols]].describe(include='all').T)


def draw_histogram(data, logx=False, logy=False, bins=100):
    """ Check the distribution of the variables in a df (and potential outliers or errors)."""
    for col in data.columns: 
        print('\n***', col, '*** :')
        sorted_values = pd.DataFrame(data[col].value_counts()).sort_index() #sort_values()
        print('50 lower and 50 higher values with the associated count:')
        display(sorted_values[:50].T.rename(index={col:'count'}))
        display(sorted_values[-50:].T.rename(index={col:'count'}))
        fig, ax = plt.subplots(figsize=(15, 4))
        # use sns and qcut?
        data[col].plot.hist(legend=True, bins=bins, 
                            logx=logx, logy=logy, title=col)
        plt.show()


"""
def draw_countplot(data, logx=False, logy=False):
    " Plot the value counts for catgeorical variables in a df."
    fig, axs =plt.subplots(3, 10)
    for ax, col in zip(axs, data.columns): 
        print('***', col, '*** :')
        # fig, ax = plt.subplots(figsize=(3, 2))
        # data[col].plot.bar(legend=True, logx=logx, logy=logy)
        order = data[col].value_counts(ascending=False).index
        ax = sns.countplot(y=col, data=data, ax=ax, order=order) 
        # to get %: sns.barplot(x=x, y=x,  estimator=percentage)
        
        ax.set_xlabel(xlabel='count', fontsize = 7) 
        ax.set_ylabel(ylabel='', fontsize = 15)
        ax.xaxis.set_tick_params(labelsize = 7)
        ax.yaxis.set_tick_params(labelsize = 10)
        ax.set_title(label = col, fontsize = 20)
        plt.show()
"""

def draw_countplot(data, logx=False, logy=False):
    " Plot the value counts for catgeorical variables in a df."
    for col in data.columns: 
        print('***', col, '*** :')
        fig, ax = plt.subplots(figsize=(3, 2))
        # data[col].plot.bar(legend=True, logx=logx, logy=logy)
        order = data[col].value_counts(ascending=False).index
        ax = sns.countplot(y=col, data=data, ax=ax, order=order) 
        # to get %: sns.barplot(x=x, y=x,  estimator=percentage)
        ax.set_xlabel(xlabel='count', fontsize = 7) 
        ax.set_ylabel(ylabel='', fontsize = 15)
        ax.xaxis.set_tick_params(labelsize = 7)
        ax.yaxis.set_tick_params(labelsize = 10)
        ax.set_title(label = col, fontsize = 20)
        plt.show()
